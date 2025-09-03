import { v4 as uuidv4 } from "uuid";
import { ai, z } from "./genkit";
import { startSessionRequestSchema } from "./schemas";
import { cacheService, CacheFlowContext } from "./cache";
import { logger } from "./logger";

export const startSessionFlow = ai.defineFlow(
  {
    name: "startSession",
    inputSchema: startSessionRequestSchema,
    outputSchema: z.string(),
  },
  async (request, flow) => {
    logger.info(
      `Received startSession request. Body: ${JSON.stringify(request, null, 2)}`
    );

    const validationResult = startSessionRequestSchema.safeParse(request);
    if (!validationResult.success) {
      const message = `Manual validation failed for startSession request:
${JSON.stringify(request, null, 2)}`;
      logger.error({ error: validationResult.error.format() }, message);
      throw new Error(message);
    }

    const resolvedCache =
      (flow.context as CacheFlowContext)?.cache || cacheService;
    logger.info("Starting new session...");
    const sessionId = uuidv4();
    logger.debug(`Generated session ID: ${sessionId}`);
    await resolvedCache.setSessionCache(
      sessionId,
      validationResult.data?.catalog
    );
    logger.info(`Successfully started session ${sessionId}`);
    return sessionId;
  }
);
