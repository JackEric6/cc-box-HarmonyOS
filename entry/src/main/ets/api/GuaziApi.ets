import { httpPost } from '../utils/HttpUtil';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { createGuaziForm, decodeGuaziResponse, guaziResponseCode, guaziResponseMessage } from './GuaziCrypto';

const BASE_URL = 'https://api.anctjd.com';
const TOKEN_KEY = 'guazi_api_token';
const DEVICE_KEY = 'guazi_device_key';

interface SignUpParams {
  old_key: string;
  new_key: string;
  phone_type: string;
  code: string;
}

interface SearchParams {
  keywords: string;
  order_val: string;
  search_type: string;
}

interface HomeParams { pid: string; }

interface CategoryParams {
  area: string;
  sub: string;
  year: string;
  pageSize: string;
  sort: string;
  page: string;
  tid: string;
}

interface PlaylistParams { show_id: string; pid: string; }
interface DetailParams { d_id: string; }
interface EpisodeParams { vurl_cloud_id: string; vod_d_id: string; }

interface PlayInfoParams {
  token_id: string;
  vod_id: string;
  mobile_time: string;
  token: string;
}

interface PlayParams {
  vod_id: string;
  domain_type: string;
  vurl_id: string;
  resolution: string;
  type: string;
}

interface RegistrationResponse { token?: string; }

function encodeForm(values: Map<string, string>): string {
  const parts: string[] = [];
  values.forEach((value: string, key: string) => {
    parts.push(encodeURIComponent(key) + '=' + encodeURIComponent(value));
  });
  return parts.join('&');
}

function asObject(value: Object): Record<string, Object> {
  if (value && typeof value === 'object' && !Array.isArray(value)) return value as Record<string, Object>;
  return {};
}

export class GuaziApi {
  private static tokenPromise: Promise<string> | null = null;

  private static async getToken(): Promise<string> {
    const token = await PreferencesUtil.get(TOKEN_KEY, '');
    if (token.length > 0) return token;
    if (!GuaziApi.tokenPromise) {
      GuaziApi.tokenPromise = GuaziApi.register().finally((): void => { GuaziApi.tokenPromise = null; });
    }
    return await GuaziApi.tokenPromise;
  }

  private static async register(): Promise<string> {
    let deviceKey = await PreferencesUtil.get(DEVICE_KEY, '');
    for (let attempt = 0; attempt < 2; attempt++) {
      if (!deviceKey) deviceKey = 'harmony-' + Date.now().toString(36) + Math.random().toString(36).substring(2, 12);
      const params: SignUpParams = {
        old_key: 'harmony-device',
        new_key: deviceKey,
        phone_type: '1',
        code: ''
      };
      try {
        const response = asObject(await GuaziApi.send('/App/Authentication/Device/signUp', params, ''));
        const registration = response as RegistrationResponse;
        const token = String(registration.token ?? '');
        if (token) {
          await PreferencesUtil.put(DEVICE_KEY, deviceKey);
          await PreferencesUtil.put(TOKEN_KEY, token);
          return token;
        }
      } catch (_e) {}
      deviceKey = '';
    }
    throw new Error('瓜子设备注册失败');
  }

  static async request(path: string, params: SignUpParams | SearchParams | HomeParams | CategoryParams |
    PlaylistParams | DetailParams | EpisodeParams | PlayInfoParams | PlayParams): Promise<Record<string, Object>> {
    let token = await GuaziApi.getToken();
    try {
      return asObject(await GuaziApi.send(path, params, token));
    } catch (e) {
      const message = String(e);
      if (!message.includes('401') && !message.includes('403') && !message.includes('token')) {
        throw new Error(message);
      }
      await PreferencesUtil.put(TOKEN_KEY, '');
      token = await GuaziApi.getToken();
      return asObject(await GuaziApi.send(path, params, token));
    }
  }

  private static async send(path: string, params: SignUpParams | SearchParams | HomeParams | CategoryParams |
    PlaylistParams | DetailParams | EpisodeParams | PlayInfoParams | PlayParams, token: string): Promise<Object> {
    const time = Math.floor(Date.now() / 1000);
    const form = await createGuaziForm(params, token, time);
    const headers = new Map<string, string>();
    headers.set('Content-Type', 'application/x-www-form-urlencoded');
    headers.set('api-ver', '3.0.5.2');
    headers.set('code', 'GZ0007');
    headers.set('lang', 'zh_cn');
    headers.set('PackageName', 'com.xcf8fa289d.s53f6f7725.hc2d9bb51620260914');
    headers.set('Ver', '3.0.5.2');
    headers.set('Version', '2608011');
    headers.set('Referer', BASE_URL);
    const raw = await httpPost(BASE_URL + path, encodeForm(form), headers);
    const code = guaziResponseCode(raw);
    if (code !== 200) throw new Error('瓜子接口错误 ' + code + ': ' + guaziResponseMessage(raw));
    return await decodeGuaziResponse(raw);
  }

  static async search(keyword: string): Promise<Record<string, Object>> {
    const params: SearchParams = { keywords: keyword, order_val: '0', search_type: '' };
    return await GuaziApi.request('/App/Index/findMoreVod', params);
  }

  static async home(): Promise<Record<string, Object>> {
    const params: HomeParams = { pid: '3' };
    return await GuaziApi.request('/App/IndexList/index', params);
  }

  static async category(tid: string, page: number, filters: Map<string, string>):
  Promise<Record<string, Object>> {
    const categorySubs: Record<string, string> = { '1': '5', '2': '12', '3': '22', '4': '30' };
    const params: CategoryParams = {
      area: filters.get('area') ?? '0',
      sub: filters.get('sub') ?? categorySubs[tid] ?? '',
      year: filters.get('year') ?? '0',
      pageSize: '30',
      sort: filters.get('sort') ?? 'd_id',
      page: String(Math.max(1, page)),
      tid: tid
    };
    return await GuaziApi.request('/App/IndexList/indexList', params);
  }

  static async homePlaylist(showId: string, pid: string): Promise<Record<string, Object>> {
    const params: PlaylistParams = { show_id: showId, pid: pid };
    return await GuaziApi.request('/App/IndexList/hotsList', params);
  }

  static async detail(id: string): Promise<Record<string, Object>> {
    const params: DetailParams = { d_id: id };
    return await GuaziApi.request('/App/Resource/Vod/showOne', params);
  }

  static async playInfo(id: string): Promise<Record<string, Object>> {
    const params: PlayInfoParams = {
      token_id: '', vod_id: id,
      mobile_time: String(Math.floor(Date.now() / 1000)),
      token: await GuaziApi.getToken()
    };
    return await GuaziApi.request('/App/IndexPlay/playInfo', params);
  }

  static async episodes(cloudId: string, vodId: string): Promise<Record<string, Object>> {
    const params: EpisodeParams = { vurl_cloud_id: cloudId, vod_d_id: vodId };
    return await GuaziApi.request('/App/Resource/Vurl/show', params);
  }

  static async play(payload: PlayParams): Promise<Record<string, Object>> {
    return await GuaziApi.request('/App/Resource/VurlDetail/showOne', payload);
  }
}
