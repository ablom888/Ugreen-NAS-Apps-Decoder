self.window = self;
importScripts('./jsrsasign-all-min.min.js');

// 监听消息
addEventListener('message', e => {
  const { task, data } = e.data;
  const id = data.id;
  try {
    switch (task) {
      case 'generateKeyPair':
        const keyPair = generateRSAKeyPair(data.bits || 2048);
        postMessage({ type: 'keyPair', value: keyPair, id });
        break;
      case 'encrypt':
        const encrypted = rsaEncrypt(data.publicKey, data.message);
        postMessage({ type: 'encrypted', value: encrypted, id });
        break;
      case 'decrypt':
        const decrypted = rsaDecrypt(data.privateKey, data.encrypted);
        postMessage({ type: 'decrypted', value: decrypted, id });
        break;
      case 'close':
        postMessage({ type: 'close', id });
        close();
        break;
    }
  } catch (error) {
    postMessage({ type: 'error', error: error.message || String(error), id });
  }
});

// 生成 RSA 密钥对
function generateRSAKeyPair(bits = 2048) {
  try {
    // 使用 jsrsasign 生成密钥对
    const keypair = KEYUTIL.generateKeypair('RSA', bits);

    // 获取私钥（PKCS8 PEM 格式）
    const privateKeyPEM = KEYUTIL.getPEM(keypair.prvKeyObj, 'PKCS8PRV');

    // 获取公钥（PEM 格式）并转换为 BEGIN RSA PUBLIC KEY 格式（与 forge 版本保持一致）
    let publicKeyPEM = KEYUTIL.getPEM(keypair.pubKeyObj);
    publicKeyPEM = publicKeyPEM.replace('BEGIN PUBLIC KEY', 'BEGIN RSA PUBLIC KEY').replace('END PUBLIC KEY', 'END RSA PUBLIC KEY');

    return {
      privateKey: privateKeyPEM,
      publicKey: publicKeyPEM,
    };
  } catch (error) {
    throw new Error(`生成密钥对失败: ${error.message || error}`);
  }
}

// RSA 加密
function rsaEncrypt(publicKeyPem, message) {
  try {
    // 处理公钥格式（jsrsasign 支持标准的 BEGIN PUBLIC KEY）
    let pem = publicKeyPem;
    if (publicKeyPem.includes('BEGIN RSA PUBLIC KEY')) {
      pem = publicKeyPem.replace('BEGIN RSA PUBLIC KEY', 'BEGIN PUBLIC KEY').replace('END RSA PUBLIC KEY', 'END PUBLIC KEY');
    }

    // 确保 message 是字符串
    if (message === undefined || message === null) {
      message = '';
    }
    if (typeof message !== 'string') {
      message = String(message);
    }

    // 使用 jsrsasign 获取公钥对象
    const publicKey = KEYUTIL.getKey(pem);

    // 使用 RSA/ECB/PKCS1Padding 加密
    const encryptedHex = KJUR.crypto.Cipher.encrypt(message, publicKey, 'RSA');

    // 将 Hex 转换为 Base64
    return hextob64(encryptedHex);
  } catch (error) {
    throw new Error(`RSA 加密失败: ${error.message || error}`);
  }
}

// RSA 解密
function rsaDecrypt(privateKeyPem, encrypted) {
  try {
    // 使用 jsrsasign 获取私钥对象
    const privateKey = KEYUTIL.getKey(privateKeyPem);

    // 将 Base64 转换为 Hex
    const encryptedHex = b64tohex(encrypted);

    // 使用 RSA/ECB/PKCS1Padding 解密
    return KJUR.crypto.Cipher.decrypt(encryptedHex, privateKey, 'RSA');
  } catch (error) {
    throw new Error(`RSA 解密失败: ${error.message || error}`);
  }
}
