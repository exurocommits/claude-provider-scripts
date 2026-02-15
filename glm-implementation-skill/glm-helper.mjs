/**
 * GLM Implementation Delegation Skill for Claude Code
 *
 * This skill allows Claude to delegate implementation tasks to Z.ai's GLM-4.6
 * while maintaining control over quality and reviewing the results.
 */

const ZAI_API_KEY = "6fb139428d1d401fbaafd80f4ca6b037.q89ixId3UUoF1LRp";
const ZAI_API_URL = "https://api.z.ai/api/coding/paas/v4/chat/completions";

// Logging function
async function logUsage(taskType, tokensUsed, success) {
  const logEntry = {
    timestamp: new Date().toISOString(),
    taskType,
    tokensUsed,
    success,
    apiKey: ZAI_API_KEY.substring(0, 10) + "..."
  };

  try {
    const fs = await import('fs');
    const logPath = "C:\\Users\\tomjo\\.claude\\glm-usage.log";
    await fs.promises.appendFile(logPath, JSON.stringify(logEntry) + "\n");
  } catch (error) {
    console.error("Failed to write usage log:", error.message);
  }
}

// Call GLM API with retry logic
async function callGLMAPI(task, context, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      console.error(`[GLM Skill] Attempt ${attempt}/${maxRetries}: Calling GLM-4.6...`);

      const response = await fetch(ZAI_API_URL, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${ZAI_API_KEY}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          model: "glm-4.6",
          messages: [
            {
              role: "system",
              content: "You are an expert programmer implementing code based on detailed specifications. Return ONLY the implementation code with brief inline comments. No explanations, no markdown formatting, just clean working code."
            },
            {
              role: "user",
              content: `TASK: ${task}\n\nCONTEXT FROM PLANNER:\n${context}\n\nImplement this task. Return only the code, no explanations.`
            }
          ],
          temperature: 0.3,
          max_tokens: 4000
        }),
        signal: AbortSignal.timeout(60000) // 60 second timeout
      });

      if (!response.ok) {
        const errorData = await response.text();
        throw new Error(`GLM API error ${response.status}: ${errorData}`);
      }

      const result = await response.json();

      if (result.error) {
        throw new Error(`GLM API returned error: ${result.error.message}`);
      }

      if (!result.choices || !result.choices[0]) {
        throw new Error("Invalid GLM API response: no choices returned");
      }

      const implementation = result.choices[0].message.content;

      // Log successful usage
      const tokensUsed = result.usage?.total_tokens || 0;
      await logUsage("implementation", tokensUsed, true);
      console.error(`[GLM Skill] Success! Used ${tokensUsed} tokens`);

      return {
        success: true,
        implementation,
        tokensUsed,
        model: result.model,
        finishReason: result.choices[0].finish_reason
      };

    } catch (error) {
      console.error(`[GLM Skill] Attempt ${attempt} failed:`, error.message);

      if (attempt === maxRetries) {
        await logUsage("implementation", 0, false);
        throw new Error(`GLM API failed after ${maxRetries} attempts: ${error.message}`);
      }

      // Exponential backoff
      const delay = Math.min(1000 * Math.pow(2, attempt - 1), 5000);
      console.error(`[GLM Skill] Waiting ${delay}ms before retry...`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
}

// Parse Claude's request to extract task and context
function parseRequest(params) {
  let task = params.task || "";
  let context = params.context || "";
  let files = params.files || [];

  // If task is not provided, try to infer from other parameters
  if (!task && params.implementation) {
    task = params.implementation;
  }

  // If files are provided, add them to context
  if (files.length > 0) {
    context += `\n\nFiles to modify:\n${files.map(f => `- ${f}`).join("\n")}`;
  }

  return { task, context };
}

// Main skill execution
export const skill = {
  name: "glm-implementation",
  description: `Delegate implementation tasks to Z.ai's GLM-4.6 model.

This skill is designed for implementation work that has already been planned by Claude.
GLM will write the actual code, which Claude should then review and refine if needed.

Best for:
- Writing boilerplate code
- Implementing straightforward features
- Creating utility functions
- Writing tests based on specifications

NOT for:
- Architecture decisions (use Claude's reasoning)
- Complex refactoring (use Claude)
- Security-critical code (use Claude)
- Anything requiring deep reasoning (use Claude)`,

  parameters: {
    task: {
      type: "string",
      description: "The specific implementation task to delegate to GLM. Be clear and specific about what needs to be implemented.",
      required: true
    },
    context: {
      type: "string",
      description: "Additional context from planning: requirements, constraints, file structure, etc.",
      required: false
    },
    files: {
      type: "array",
      items: { type: "string" },
      description: "List of files that will be modified or created",
      required: false
    }
  },

  async execute(params) {
    console.error("\n" + "=".repeat(60));
    console.error("[GLM Skill] 🔄 Starting implementation delegation...");
    console.error("=".repeat(60) + "\n");

    try {
      // Parse the request
      const { task, context } = parseRequest(params);

      if (!task) {
        throw new Error("Task parameter is required");
      }

      console.error("[GLM Skill] Task:", task);
      console.error("[GLM Skill] Context:", context || "(none provided)");
      console.error("");

      // Call GLM API with retry logic
      const result = await callGLMAPI(task, context);

      // Display results
      console.error("\n" + "=".repeat(60));
      console.error("[GLM Skill] ✅ Implementation Complete!");
      console.error("=".repeat(60));
      console.error(`[GLM Skill] Model: ${result.model}`);
      console.error(`[GLM Skill] Tokens: ${result.tokensUsed}`);
      console.error(`[GLM Skill] Finish Reason: ${result.finishReason}`);
      console.error("=".repeat(60) + "\n");

      // Return structured result for Claude to review
      return {
        success: true,
        implementation: result.implementation,
        tokensUsed: result.tokensUsed,
        model: result.model,
        message: `Implementation delegated to GLM-4.6 (${result.tokensUsed} tokens used). Please review the code below and refine as needed:\n\n${result.implementation}`,

        // Extra context for Claude
        reviewChecklist: [
          "✓ Check for security vulnerabilities",
          "✓ Verify error handling",
          "✓ Ensure type safety",
          "✓ Validate edge cases",
          "✓ Add necessary comments",
          "✓ Test the implementation if possible"
        ]
      };

    } catch (error) {
      console.error("\n" + "=".repeat(60));
      console.error("[GLM Skill] ❌ DELEGATION FAILED");
      console.error("=".repeat(60));
      console.error("[GLM Skill] Error:", error.message);
      console.error("=".repeat(60) + "\n");

      return {
        success: false,
        error: error.message,
        message: `Failed to delegate to GLM: ${error.message}\n\nPlease implement this task yourself or try again.`,
        fallback: "Consider using Claude's own implementation capabilities instead."
      };
    }
  }
};

// Export for testing
if (import.meta.url === `file://${process.argv[1]}`) {
  // Test mode
  console.error("GLM Skill: Running in test mode...");

  skill.execute({
    task: "Create a function to validate email addresses using regex",
    context: "Should return boolean, handle edge cases"
  })
  .then(result => {
    console.error("\n=== TEST RESULT ===");
    console.error(JSON.stringify(result, null, 2));
  })
  .catch(error => {
    console.error("TEST FAILED:", error);
  });
}
