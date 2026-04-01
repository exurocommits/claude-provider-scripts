---
name: glm-implementation
description: Delegate implementation tasks to Z.ai's GLM-4.6 model for boilerplate code, utility functions, and straightforward features. Use this when you need to implement well-defined code while saving Claude subscription tokens.
allowed-tools: Bash
---

# GLM Implementation Delegation

## Purpose
This skill allows you to delegate implementation work to Z.ai's GLM-4.6 model while maintaining quality control. GLM handles the coding, you review and refine the results.

## When to Use This Skill

### ✅ GOOD Use Cases:
- **Boilerplate code** - CRUD operations, standard patterns
- **Utility functions** - formatters, validators, helpers
- **Simple features** - straightforward implementations with clear requirements
- **Test generation** - unit tests based on specifications
- **Documentation** - JSDoc comments, inline documentation

### ❌ DON'T Use For:
- **Architecture decisions** - requires deep reasoning
- **Security-critical code** - needs expert review
- **Complex refactoring** - involves trade-offs
- **Performance optimization** - requires analysis
- **Debugging** - needs investigation

## How to Execute

Use the GLM implementation helper script:

```bash
node C:\Users\tomjo\.claude\skills\glm-implementation\glm-helper.mjs --task "YOUR_TASK" --context "CONTEXT"
```

### Parameters:
- `--task` (required): Specific implementation task
- `--context` (optional): Additional context, requirements, constraints
- `--files` (optional): Comma-separated list of files to modify

## Workflow

1. **User Request**: User asks for implementation
2. **You Plan**: Analyze if task is suitable for GLM delegation
3. **Delegate**: Use this skill to call GLM-4.6
4. **Review**: Critically review GLM's output for:
   - Security vulnerabilities
   - Error handling
   - Type safety
   - Edge cases
   - Code quality
5. **Refine**: Improve the code as needed
6. **Present**: Show final implementation to user

## Example Usage

**User**: "Create an email validator function"

**You**: "This is a good task for GLM delegation - it's a straightforward utility function."

**Execute**:
```bash
node C:\Users\tomjo\.claude\skills\glm-implementation\glm-helper.mjs --task "Create a function that validates email addresses using regex, returns boolean" --context "Should handle common edge cases like plus addressing and international domains"
```

**Review**: Check GLM's regex pattern, test coverage, edge cases

**Refine**: Add JSDoc comments, improve edge case handling if needed

**Present**: Final validated implementation to user

## Quality Checklist

After receiving GLM's implementation, always verify:
- [ ] No security vulnerabilities (XSS, injection, etc.)
- [ ] Proper error handling
- [ ] Type safety (TypeScript types if applicable)
- [ ] Edge cases covered
- [ ] Clear variable/function names
- [ ] Necessary comments added
- [ ] Follows project conventions

## Configuration

**API Endpoint**: https://api.z.ai/api/coding/paas/v4/chat/completions
**Model**: glm-4.6
**API Key**: Stored in helper script
**Logs**: C:\Users\tomjo\.claude\glm-usage.log

## Notes

- GLM uses your Z.ai Coding Plan quota (96% remaining as of last check)
- Failed calls are automatically retried up to 3 times
- All usage is logged for monitoring
- Token usage is tracked per request
- This saves your Claude subscription tokens for planning and review
