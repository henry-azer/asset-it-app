import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

class EncryptionService {
  static const String _defaultPassword = 'AssetIt_Backup_2024_Secure_V2';
  static const int _pbkdf2Iterations = 5;
  static const int _saltLength = 32;
  static const int _ivLength = 12;
  static const int _tagLength = 16;
  static const int _keyLength = 32;
  static const int _version = 1;
  
  static final _random = Random.secure();

  static Uint8List _generateRandomBytes(int length) {
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }

  static Uint8List _deriveKey(String password, Uint8List salt) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA512Digest(), 128));
    derivator.init(Pbkdf2Parameters(salt, _pbkdf2Iterations, _keyLength));
    return derivator.process(Uint8List.fromList(utf8.encode(password)));
  }

  static Uint8List encrypt(String plainText, {String? password}) {
    try {
      final salt = _generateRandomBytes(_saltLength);
      final key = _deriveKey(password ?? _defaultPassword, salt);
      final iv = _generateRandomBytes(_ivLength);
      
      final cipher = GCMBlockCipher(AESEngine());
      final params = AEADParameters(
        KeyParameter(key),
        _tagLength * 8,
        iv,
        Uint8List.fromList(utf8.encode('AssetIt-Backup-V$_version')),
      );
      
      cipher.init(true, params);
      
      final plainBytes = Uint8List.fromList(utf8.encode(plainText));
      final encryptedBytes = cipher.process(plainBytes);
      
      final result = BytesBuilder();
      result.addByte(_version);
      result.add(salt);
      result.add(iv);
      result.add(encryptedBytes);
      
      final finalData = result.toBytes();
      final hmac = _generateHMAC(finalData, key);
      
      final finalResult = BytesBuilder();
      finalResult.add(finalData);
      finalResult.add(hmac);
      
      return finalResult.toBytes();
    } catch (e) {
      throw Exception('Encryption failed: ${e.toString()}');
    }
  }

  static String decrypt(Uint8List encryptedData, {String? password}) {
    try {
      final minLength = 1 + _saltLength + _ivLength + _tagLength + 32;
      if (encryptedData.length < minLength) {
        return _fallbackDecrypt(encryptedData);
      }

      final hmacLength = 32;
      final dataWithoutHmac = encryptedData.sublist(0, encryptedData.length - hmacLength);
      final receivedHmac = encryptedData.sublist(encryptedData.length - hmacLength);
      
      int offset = 0;
      final version = encryptedData[offset];
      offset += 1;

      if (version != _version) {
        return _fallbackDecrypt(encryptedData);
      }

      final salt = encryptedData.sublist(offset, offset + _saltLength);
      offset += _saltLength;

      final iv = encryptedData.sublist(offset, offset + _ivLength);
      offset += _ivLength;

      final ciphertext = encryptedData.sublist(offset, encryptedData.length - hmacLength);

      final key = _deriveKey(password ?? _defaultPassword, salt);
      
      final computedHmac = _generateHMAC(dataWithoutHmac, key);
      if (!_constantTimeCompare(receivedHmac, computedHmac)) {
        throw Exception('HMAC verification failed - data may be tampered');
      }

      final cipher = GCMBlockCipher(AESEngine());
      final params = AEADParameters(
        KeyParameter(key),
        _tagLength * 8,
        iv,
        Uint8List.fromList(utf8.encode('AssetIt-Backup-V$_version')),
      );
      
      cipher.init(false, params);
      
      final decryptedBytes = cipher.process(ciphertext);
      return utf8.decode(decryptedBytes);
    } catch (e) {
      return _fallbackDecrypt(encryptedData);
    }
  }

  static Uint8List _generateHMAC(Uint8List data, Uint8List key) {
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(data);
    return Uint8List.fromList(digest.bytes);
  }

  static bool _constantTimeCompare(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  static String _fallbackDecrypt(Uint8List data) {
    try {
      return utf8.decode(data);
    } catch (e) {
      throw Exception('Decryption failed: Invalid or corrupted data');
    }
  }

  static bool isEncrypted(Uint8List data) {
    if (data.isEmpty) return false;
    
    try {
      if (data[0] == _version) {
        return true;
      }
      
      final testString = utf8.decode(data);
      if (testString.startsWith('{') || testString.startsWith('[')) {
        return false;
      }
      return true;
    } catch (e) {
      return true;
    }
  }
}
