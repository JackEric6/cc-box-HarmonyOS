import { PlayInfo } from '../model/Movie';
import { SourceBean as SourceConfig } from '../model/SourceBean';
import { GuaziApi } from './GuaziApi';
import { Spider } from './Spider';

interface HomeSection {
  showId: string;
  title: string;
  pid: string;
}

const HOME_SECTIONS: HomeSection[] = [
  { showId: '74151', title: '重磅新剧', pid: '4' },
  { showId: '46296', title: '最新热播电影', pid: '3' },
  { showId: '19260', title: 'TC抢先看', pid: '3' },
  { showId: '17613', title: '豆瓣电影TOP250', pid: '3' },
  { showId: '130', title: 'Netflix新片推荐', pid: '1' },
  { showId: '10772', title: '入站必追', pid: '5' },
  { showId: '24058', title: '爱奇艺剧场', pid: '4' },
  { showId: '24066', title: '优酷剧场', pid: '4' },
  { showId: '24057', title: '腾讯剧场', pid: '4' },
  { showId: '24067', title: '芒果剧场', pid: '4' },
  { showId: '38579', title: '大厂VIP短剧专区', pid: '16' },
  { showId: '16560', title: '历届奥斯卡最佳影片', pid: '3' },
  { showId: '8', title: '冷门悬疑佳片Top20', pid: '3' },
  { showId: '6663', title: '近期热门综艺', pid: '6' }
];

interface EpisodePayload {
  vod_id: string;
  domain_type: string;
  vurl_id: string;
  resolution: string;
  type: string;
}

interface GuaziVod {
  vod_id: string;
  vod_name: string;
  vod_pic: string;
  vod_year: string;
  vod_area: string;
  vod_actor: string;
  vod_director: string;
  type_name: string;
  vod_score: string;
  vod_remarks: string;
  vod_content: string;
  vod_play_from: string;
  vod_play_url: string;
}

interface GuaziClassItem {
  type_id: string;
  type_name: string;
}

interface GuaziPageResult {
  code: number;
  page: number;
  pagecount: number;
  limit: number;
  total: number;
  list: GuaziVod[];
}

function makeClassItem(section: HomeSection): GuaziClassItem {
  return {
    type_id: 'guazi-playlist:' + section.pid + ':' + section.showId,
    type_name: section.title
  };
}

function stringValue(object: Record<string, Object>, keys: string[]): string {
  for (const key of keys) {
    const value = object[key];
    if (value !== undefined && value !== null && String(value).trim().length > 0) return String(value).trim();
  }
  return '';
}

function firstArray(object: Record<string, Object>, keys: string[]): Object[] {
  for (const key of keys) {
    const value = object[key];
    if (Array.isArray(value) && value.length > 0) return value as Object[];
  }
  for (const key of keys) {
    const nested = object[key];
    if (nested && typeof nested === 'object' && !Array.isArray(nested)) {
      const result = firstArray(nested as Record<string, Object>, keys);
      if (result.length > 0) return result;
    }
  }
  return [];
}

function mapVod(source: Record<string, Object>): GuaziVod {
  const content = stringValue(source, [
    'vod_use_content', 'd_content', 'd_blurb', 'd_desc', 'd_description', 'd_intro', 'd_synopsis',
    'd_summary', 'vod_content', 'vod_blurb', 'vod_desc', 'vod_description', 'vod_intro', 'vod_summary',
    'synopsis', 'summary', 'intro', 'introduction', 'description', 'desc', 'content'
  ]).replace(/<br\s*\/?>/gi, '\n').replace(/<\/p>/gi, '\n').replace(/<[^>]+>/g, '').trim();
  const vod: GuaziVod = {
    vod_id: stringValue(source, ['vod_id', 'd_id', 'id', 'show_id', 'vodId']),
    vod_name: stringValue(source, ['vod_name', 'd_name', 'c_name', 'name', 'title', 'vod_title']),
    vod_pic: stringValue(source, ['vod_pic', 'd_pic', 'c_pic', 'pic']),
    vod_year: stringValue(source, ['vod_year', 'd_year']),
    vod_area: stringValue(source, ['vod_area', 'd_area']),
    vod_actor: stringValue(source, ['vod_actor', 'd_actor']),
    vod_director: stringValue(source, ['vod_director', 'vod_directed']),
    type_name: stringValue(source, ['vod_class', 'd_type', 'd_class', 'type_name']),
    vod_score: stringValue(source, ['vod_score', 'vod_scroe', 'vod_douban_score']),
    vod_remarks: stringValue(source, ['new_continue', 'vod_remarks', 'vod_title', 'cf_name', 'sub_title']),
    vod_content: content,
    vod_play_from: '',
    vod_play_url: ''
  };
  return vod;
}

function mergeVod(first: GuaziVod, second: GuaziVod): GuaziVod {
  const merged: GuaziVod = {
    vod_id: first.vod_id, vod_name: first.vod_name, vod_pic: first.vod_pic, vod_year: first.vod_year,
    vod_area: first.vod_area, vod_actor: first.vod_actor, vod_director: first.vod_director,
    type_name: first.type_name, vod_score: first.vod_score, vod_remarks: first.vod_remarks,
    vod_content: first.vod_content, vod_play_from: first.vod_play_from, vod_play_url: first.vod_play_url
  };
  if (second.vod_id) merged.vod_id = second.vod_id;
  if (second.vod_name) merged.vod_name = second.vod_name;
  if (second.vod_pic) merged.vod_pic = second.vod_pic;
  if (second.vod_year) merged.vod_year = second.vod_year;
  if (second.vod_area) merged.vod_area = second.vod_area;
  if (second.vod_actor) merged.vod_actor = second.vod_actor;
  if (second.vod_director) merged.vod_director = second.vod_director;
  if (second.type_name) merged.type_name = second.type_name;
  if (second.vod_score) merged.vod_score = second.vod_score;
  if (second.vod_remarks) merged.vod_remarks = second.vod_remarks;
  if (second.vod_content) merged.vod_content = second.vod_content;
  if (second.vod_play_from) merged.vod_play_from = second.vod_play_from;
  if (second.vod_play_url) merged.vod_play_url = second.vod_play_url;
  return merged;
}

function episodePayload(vodId: string, cloudId: string, episode: Record<string, Object>): EpisodePayload | null {
  const vurlId = stringValue(episode, ['id', 'vurl_id']);
  const play = episode['play'] as Record<string, Object> | undefined;
  if (!vurlId || !play) return null;
  for (const resolution of ['720', '1080', '480']) {
    const item = play[resolution] as Record<string, Object> | undefined;
    const rawParam = item ? item['param'] : undefined;
    if (!rawParam) continue;
    const param: Record<string, Object> = {};
    if (typeof rawParam === 'string') {
      for (const part of rawParam.split('&')) {
        const split = part.indexOf('=');
        if (split > 0) {
          param[decodeURIComponent(part.substring(0, split))] =
            decodeURIComponent(part.substring(split + 1).replace(/\+/g, ' '));
        }
      }
    } else if (typeof rawParam === 'object' && !Array.isArray(rawParam)) {
      const rawFields = rawParam as Record<string, Object>;
      for (const key of Object.keys(rawFields)) param[key] = rawFields[key];
    }
    const domainType = stringValue(param, ['domain_type']);
    const selectedResolution = stringValue(param, ['resolution']) || resolution;
    const type = stringValue(param, ['type']) || 'play';
    if (domainType) return { vod_id: vodId, domain_type: domainType, vurl_id: vurlId,
      resolution: selectedResolution, type: type };
  }
  return null;
}

function playableUrl(value: Object): string {
  if (typeof value === 'string') {
    const url = value.trim();
    if (/^https?:\/\//i.test(url) && /\.(m3u8|mp4|mpd)(\?|$)/i.test(url)) return url;
    return '';
  }
  if (Array.isArray(value)) {
    for (const item of value as Object[]) {
      const url = playableUrl(item);
      if (url) return url;
    }
    return '';
  }
  if (value && typeof value === 'object') {
    const object = value as Record<string, Object>;
    for (const key of ['url', 'play_url', 'playUrl', 'm3u8', 'video_url', 'videoUrl', 'data', 'result']) {
      const child = object[key];
      if (child !== undefined) {
        const url = playableUrl(child);
        if (url) return url;
      }
    }
    for (const key of Object.keys(object)) {
      const url = playableUrl(object[key]);
      if (url) return url;
    }
  }
  return '';
}

export class GuaziSpider extends Spider {
  private catalog: Map<string, GuaziVod> = new Map();

  override init(bean: SourceConfig): void {
    this.siteKey = bean.key;
    this.siteApi = bean.api;
    this.sourceBean = bean;
  }

  override async homeContent(_filter: boolean): Promise<string> {
    const list = await GuaziSpider.loadPlaylist(HOME_SECTIONS[0]);
    const classes: GuaziClassItem[] = HOME_SECTIONS.map((section: HomeSection): GuaziClassItem => makeClassItem(section));
    return JSON.stringify({
      class: classes,
      code: 1, page: 1, pagecount: 1, limit: 30, total: list.length, list: list
    });
  }

  override async homeVideoContent(): Promise<string> {
    const list = await GuaziSpider.loadPlaylist(HOME_SECTIONS[0]);
    return JSON.stringify({ page: 1, pagecount: 1, limit: 30, total: list.length, list: list });
  }

  override async categoryContent(tid: string, pg: number, extend: Map<string, string>): Promise<string> {
    if (tid.startsWith('guazi-playlist:')) {
      const parts = tid.split(':');
      const section: HomeSection = { pid: parts[1] ?? '3', showId: parts[2] ?? '', title: tid };
      const list = pg > 1 ? [] : await GuaziSpider.loadPlaylist(section);
      return JSON.stringify({ code: list.length ? 1 : 0, page: pg, pagecount: 1, limit: 30, total: list.length, list: list });
    }
    const response = await GuaziApi.category(tid, pg, extend);
    return JSON.stringify(GuaziSpider.mapPage(response, this.catalog));
  }

  override async searchContent(key: string, _quick: boolean, _pg?: number): Promise<string> {
    const response = await GuaziApi.search(key);
    const list = firstArray(response, ['list', 'data', 'result', 'payload']);
    const mapped: Object[] = [];
    for (const raw of list) {
      if (!raw || typeof raw !== 'object' || Array.isArray(raw)) continue;
      const vod = mapVod(raw as Record<string, Object>);
      if (!vod.vod_id) continue;
      this.catalog.set(vod.vod_id, vod);
      mapped.push(vod);
    }
    return JSON.stringify({ code: mapped.length ? 1 : 0, page: 1, pagecount: 1, total: mapped.length, list: mapped });
  }

  override async detailContent(ids: string[]): Promise<string> {
    const id = ids.length > 0 ? ids[0] : '';
    const response = await GuaziApi.detail(id);
    const rawList = firstArray(response, ['list', 'data', 'result', 'payload']);
    let source = response;
    if (rawList.length > 0 && rawList[0] && typeof rawList[0] === 'object') {
      source = rawList[0] as Record<string, Object>;
    } else {
      for (const key of ['data', 'result', 'payload', 'vod', 'info']) {
        const nested = response[key];
        if (nested && typeof nested === 'object' && !Array.isArray(nested)) {
          source = nested as Record<string, Object>;
          break;
        }
      }
    }
    const cached = this.catalog.get(id);
    let vod = cached ? mergeVod(cached, mapVod(source)) : mapVod(source);
    if (!vod['vod_content']) {
      try {
        vod = mergeVod(vod, mapVod(await GuaziApi.playInfo(id)));
      } catch (_e) {}
    }
    vod['vod_id'] = id;
    if (!vod['vod_name']) vod['vod_name'] = id;
    const clouds = (source['vurl_clouds'] as Object[] | undefined) ?? [];
    const flags: string[] = [];
    const groups: string[] = [];
    for (const rawCloud of clouds) {
      if (!rawCloud || typeof rawCloud !== 'object') continue;
      const cloud = rawCloud as Record<string, Object>;
      const cloudId = stringValue(cloud, ['id']);
      if (!cloudId) continue;
      const episodeResponse = await GuaziApi.episodes(cloudId, id);
      const episodes = firstArray(episodeResponse, ['list', 'data', 'result', 'payload']);
      const urls: string[] = [];
      for (const rawEpisode of episodes) {
        if (!rawEpisode || typeof rawEpisode !== 'object') continue;
        const episode = rawEpisode as Record<string, Object>;
        const payload = episodePayload(id, cloudId, episode);
        if (!payload) continue;
        const title = stringValue(episode, ['title', 'name']) || String(urls.length + 1);
        urls.push(title + '$ccbox-guazi://play/' + encodeURIComponent(JSON.stringify(payload)));
      }
      if (urls.length > 0) {
        flags.push(stringValue(cloud, ['name']) || '瓜子线路');
        groups.push(urls.join('#'));
      }
    }
    vod['vod_play_from'] = flags.join('$$$');
    vod['vod_play_url'] = groups.join('$$$');
    return JSON.stringify({ code: 1, page: 1, pagecount: 1, total: 1, list: [vod] });
  }

  override async playerContent(_flag: string, id: string): Promise<PlayInfo | null> {
    const prefix = 'ccbox-guazi://play/';
    if (!id.startsWith(prefix)) return await super.playerContent(_flag, id);
    const payload = JSON.parse(decodeURIComponent(id.substring(prefix.length))) as EpisodePayload;
    const result = await GuaziApi.play(payload);
    const url = playableUrl(result);
    if (!url) throw new Error('瓜子播放接口没有返回媒体地址');
    return { url: url, header: new Map<string, string>(), parse: 0, jx: 0 };
  }

  private static async loadPlaylist(section: HomeSection): Promise<Object[]> {
    const response = await GuaziApi.homePlaylist(section.showId, section.pid);
    return GuaziSpider.mapPage(response, new Map<string, Record<string, Object>>()).list as Object[];
  }

  private static mapPage(response: Record<string, Object>, cache: Map<string, GuaziVod>): GuaziPageResult {
    const sourceList = firstArray(response, ['list', 'data', 'result', 'payload']);
    const list: GuaziVod[] = [];
    for (const raw of sourceList) {
      if (!raw || typeof raw !== 'object' || Array.isArray(raw)) continue;
      const vod = mapVod(raw as Record<string, Object>);
      const id = vod.vod_id;
      if (!id) continue;
      cache.set(id, vod);
      list.push(vod);
    }
    const total = Number(response['total'] ?? list.length);
    const result: GuaziPageResult = { code: list.length ? 1 : 0, page: Number(response['page'] ?? 1),
      pagecount: Number(response['pagecount'] ?? Math.max(1, Math.ceil(total / 30))),
      limit: 30, total: Math.max(total, list.length), list: list };
    return result;
  }
}
