import { ICacheService } from '../cache';

export class FakeCacheService implements ICacheService {
  private cache = new Map<string, Record<string, unknown>>();

  async setSessionCache(
    sessionId: string,
    catalog: Record<string, unknown>
  ): Promise<void> {
    console.log('FakeCacheService.setSessionCache', sessionId, catalog);
    this.cache.set(sessionId, catalog);
  }

  async getSessionCache(
    sessionId: string
  ): Promise<Record<string, unknown> | null> {
    return this.cache.get(sessionId) || null;
  }
}
