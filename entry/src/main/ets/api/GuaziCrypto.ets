import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { buffer } from '@kit.ArkTS';
import { base64Decode, base64Encode, bytesToHex, hexToBytes, md5 } from '../util/AESUtil';

const SIGN_SALT = '*&zvdvdvddbfikkkumtmdwqppp?|4Y!s!2br';
const RSA_PUBLIC_KEY =
  'MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDUM5+/y8sPsWkd1/RQS64X259EUwxFXFE5HlA65MqrxnPs0JqoSRojSDy5QhwvROlaD6TwRQHKMY2OAZ6SnQeUJsChTEFIR9qUkwrs3/MVUMxjsv6JS6Oe/juclyJGTgVmDhB55EafXsD0SQYVj/QXXsxR6ewR5E2kL52yAAD4yQIDAQAB';
const RSA_PRIVATE_KEY =
  'MIICdgIBADANBgkqhkiG9w0BAQEFAASCAmAwggJcAgEAAoGAe6hKrWLi1zQmjTT1ozbE4QdFeJGNxubxld6GrFGximxfMsMB6BpJhpcTouAqywAFppiKetUBBbXwYsYU1wNr648XVmPmCMCy4rY8vdliFnbMUj086DU6Z+/oXBdWU3/b1G0DN3E9wULRSwcKZT3wj/cCI1vsCm3gj2R5SqkA9Y0CAwEAAQKBgAJH+4CxV0/zBVcLiBCHvSANm0l7HetybTh/j2p0Y1sTXro4ALwAaCTUeqdBjWiLSo9lNwDHFyq8zX90+gNxa7c5EqcWV9FmlVXr8VhfBzcZo1nXeNdXFT7tQ2yah/odtdcx+vRMSGJd1t/5k5bDd9wAvYdIDblMAg+wiKKZ5KcdAkEA1cCakEN4NexkF5tHPRrR6XOY/XHfkqXxEhMqmNbB9U34saTJnLWIHC8IXys6Qmzz30TtzCjuOqKRRy+FMM4TdwJBAJQZFPjsGC+RqcG5UvVMiMPhnwe/bXEehShK86yJK/g/UiKrO87h3aEu5gcJqBygTq3BBBoH2md3pr/W+hUMWBsCQQChfhTIrdDinKi6lRxrdBnn0Ohjg2cwuqK5zzU9p/N+S9x7Ck8wUI53DKm8jUJE8WAG7WLj/oCOWEh+ic6NIwTdAkEAj0X8nhx6AXsgCYRql1klbqtVmL8+95KZK7PnLWG/IfjQUy3pPGoSaZ7fdquG8bq8oyf5+dzjE/oTXcByS+6XRQJAP/5ciy1bL3NhUhsaOVy55MHXnPjdcTX0FaLi+ybXZIfIQ2P4rb19mVq1feMbCXhz+L1rG8oat5lYKfpe8k83ZA==';

function utf8(value: string): Uint8Array {
  return new Uint8Array(buffer.from(value, 'utf-8').buffer);
}

function randomText(length: number): string {
  const random = cryptoFramework.createRandom();
  const bytes = random.generateRandomSync(length * 2).data;
  const alphabet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let result = '';
  for (let i = 0; i < length; i++) result += alphabet[bytes[i] % alphabet.length];
  return result;
}

async function rsaCrypt(value: string, encrypt: boolean): Promise<string> {
  const generator = cryptoFramework.createAsyKeyGenerator('RSA1024');
  const pair = encrypt
    ? await generator.convertKey({ data: base64Decode(RSA_PUBLIC_KEY) }, null)
    : await generator.convertKey(null, { data: base64Decode(RSA_PRIVATE_KEY) });
  const cipher = cryptoFramework.createCipher('RSA1024|PKCS1');
  await cipher.init(
    encrypt ? cryptoFramework.CryptoMode.ENCRYPT_MODE : cryptoFramework.CryptoMode.DECRYPT_MODE,
    encrypt ? pair.pubKey : pair.priKey,
    null
  );
  const input = encrypt ? utf8(value) : base64Decode(value);
  const result = await cipher.doFinal({ data: input });
  return encrypt ? base64Encode(result.data) : buffer.from(result.data).toString('utf-8');
}

async function aesCrypt(value: string, key: string, iv: string, encrypt: boolean): Promise<string> {
  const keyGenerator = cryptoFramework.createSymKeyGenerator('AES128');
  const symKey = await keyGenerator.convertKey({ data: utf8(key) });
  const cipher = cryptoFramework.createCipher('AES128|CBC|PKCS7');
  const ivSpec: cryptoFramework.IvParamsSpec = { algName: 'IvParamsSpec', iv: { data: utf8(iv) } };
  await cipher.init(
    encrypt ? cryptoFramework.CryptoMode.ENCRYPT_MODE : cryptoFramework.CryptoMode.DECRYPT_MODE,
    symKey,
    ivSpec
  );
  const result = await cipher.doFinal({ data: encrypt ? utf8(value) : hexToBytes(value) });
  return encrypt ? bytesToHex(result.data).toUpperCase() : buffer.from(result.data).toString('utf-8');
}

export async function createGuaziForm(params: Record<string, Object>, token: string, time: number):
Promise<Map<string, string>> {
  const key = randomText(16);
  const iv = randomText(16);
  const requestKey = await aesCrypt(JSON.stringify(params), key, iv, true);
  const keys = await rsaCrypt(JSON.stringify({ key: key, iv: iv }), true);
  const signatureText = 'token_id=,token=' + token + ',phone_type=1,request_key=' + requestKey +
    ',app_id=1,time=' + String(time) + ',keys=' + keys;
  const signature = (await md5(signatureText + SIGN_SALT)).toUpperCase();
  const form = new Map<string, string>();
  form.set('token', token);
  form.set('token_id', '');
  form.set('phone_type', '1');
  form.set('time', String(time));
  form.set('phone_model', 'Android-TVBox');
  form.set('keys', keys);
  form.set('request_key', requestKey);
  form.set('signature', signature);
  form.set('app_id', '1');
  form.set('ad_version', '1');
  return form;
}

export async function decodeGuaziResponse(raw: string): Promise<Object> {
  const outer = JSON.parse(raw) as Record<string, Object>;
  const data = outer['data'] as Record<string, Object> | undefined;
  if (!data || typeof data['keys'] !== 'string' || typeof data['response_key'] !== 'string') {
    throw new Error('瓜子响应缺少加密数据');
  }
  const session = JSON.parse(await rsaCrypt(data['keys'] as string, false)) as Record<string, Object>;
  const key = String(session['key'] ?? '');
  const iv = String(session['iv'] ?? '');
  if (!key || !iv) throw new Error('瓜子响应会话密钥无效');
  return JSON.parse(await aesCrypt(data['response_key'] as string, key, iv, false)) as Object;
}

export function guaziResponseCode(raw: string): number {
  try {
    return Number((JSON.parse(raw) as Record<string, Object>)['code'] ?? 0);
  } catch (_e) {
    return 0;
  }
}

export function guaziResponseMessage(raw: string): string {
  try {
    return String((JSON.parse(raw) as Record<string, Object>)['msg'] ?? '');
  } catch (_e) {
    return '';
  }
}
