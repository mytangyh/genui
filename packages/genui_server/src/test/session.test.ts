import { startSessionFlow } from "../session";
import { v4 as uuidv4 } from "uuid";
import { FakeCacheService } from "./fake-cache-service";

jest.mock("uuid", () => ({
  v4: jest.fn(),
}));

describe("startSessionFlow", () => {
  it("should start a session and return a session ID", async () => {
    const mockSessionId = "mock-session-id";
    (uuidv4 as jest.Mock).mockReturnValue(mockSessionId);
    const fakeCache = new FakeCacheService();

    const catalog = { version: "1.0" };
    const sessionId = await startSessionFlow.run(
      {
        protocolVersion: "0.1.0",
        catalog,
      },
      { context: { cache: fakeCache } }
    );

    expect(sessionId.result).toBe(mockSessionId);
    expect(await fakeCache.getSessionCache(mockSessionId)).toEqual(catalog);
  });
});
