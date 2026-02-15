# GLM Implementation Skill - Complete Guide

## 🎯 What This Skill Does

**Delegates implementation work to GLM-4.6 while Claude stays in control.**

```
You (planning) → Claude (reasoning) → GLM (implementation) → Claude (review) → You
```

---

## ✅ How It Works

### 1. **Claude Plans**
You describe what you want, Claude thinks through the approach.

### 2. **Claude Delegates**
Claude decides: "This implementation is straightforward, I'll delegate it to GLM."

### 3. **GLM Implements**
GLM writes the actual code based on Claude's specifications.

### 4. **Claude Reviews**
Claude checks GLM's work, refines if needed, presents final result to you.

---

## 🚀 How to Use It

### **Automatic Usage (Claude's Choice)**

Just ask Claude to implement something. If it's suitable, Claude will use the skill:

```
You: Implement user authentication with JWT and bcrypt

Claude: I'll delegate the implementation to GLM...
[Uses glm-implementation skill]
[Claude reviews the code]
Here's the refined implementation...
```

### **Manual Usage (Explicit Request)**

Tell Claude to use the skill:

```
You: Use glm-implementation to create the database models

Claude: [Invokes skill with your task]
```

### **With Context**

Provide context for better results:

```
You: Use glm-implementation with these files:
- models/User.ts
- utils/auth.ts

Task: Add password reset functionality

Claude: [Delegates with proper context]
```

---

## 📋 When Will Claude Use It?

### ✅ **Good Use Cases (Claude SHOULD delegate):**

- **Boilerplate code** - CRUD operations, standard patterns
- **Utility functions** - formatters, validators, helpers
- **Simple features** - straightforward implementations
- **Tests** - unit tests based on specifications
- **Refactoring** - simple code improvements
- **Documentation** - generating JSDoc, comments

Examples:
```
✓ "Create a regex validator for email addresses"
✓ "Implement a retry wrapper for API calls"
✓ "Write unit tests for the user service"
✓ "Generate JSDoc comments for this file"
✓ "Refactor this to use async/await"
```

### ❌ **Bad Use Cases (Claude should NOT delegate):**

- **Architecture decisions** - requires deep reasoning
- **Security-critical code** - needs expert review
- **Complex refactoring** - involves trade-offs
- **Performance optimization** - requires analysis
- **Debugging** - needs investigation
- **API design** - strategic thinking

Examples:
```
✗ "Design the microservices architecture"
✗ "Fix this security vulnerability"
✗ "Optimize this database query"
✗ "Debug why auth is failing"
✗ "Design the REST API structure"
```

---

## 🔧 Ensuring It Gets Called When Needed

### **1. Set Clear Expectations**

Tell Claude when you want delegation:

```
You: For implementation tasks, delegate to GLM and review the results

Claude: [Will use skill appropriately]
```

### **2. Add to CLAUDE.md**

Create `~/.claude/CLAUDE.md` with guidelines:

```markdown
# When to Use GLM Implementation Skill

Use the glm-implementation skill for:
- Boilerplate and routine code
- Well-defined implementation tasks
- Test generation
- Documentation

Do NOT use for:
- Architecture decisions
- Security-critical code
- Complex refactoring
- Performance optimization

Always review GLM's output before presenting to user.
```

### **3. Lead by Example**

When you see good delegation, reinforce it:

```
You: Great delegation! That's exactly when to use GLM.
```

### **4. Correct When Needed**

If Claude delegates something it shouldn't:

```
You: Please implement this yourself - it requires security expertise.
```

---

## 📊 Monitoring & Logs

### **Check Usage**

```powershell
# View recent GLM usage
Get-Content C:\Users\tomjo\.claude\glm-usage.log -Tail 20
```

### **Log Format**

Each log entry shows:
```json
{
  "timestamp": "2026-01-03T...",
  "taskType": "implementation",
  "tokensUsed": 1234,
  "success": true,
  "apiKey": "6fb139428..."
}
```

---

## 🧪 Testing the Skill

### **Quick Test**

Run the test script:
```powershell
C:\dev\test-glm-skill.bat
```

### **Test in Claude**

```powershell
# Start Claude
claude

# Test the skill
You: Use glm-implementation to create a function that validates phone numbers
```

**Expected Output:**
```
[GLM Skill] 🔄 Starting implementation delegation...
[GLM Skill] Task: Create a function that validates phone numbers
[GLM Skill] Attempt 1/3: Calling GLM-4.6...
[GLM Skill] Success! Used 234 tokens
[GLM Skill] ✅ Implementation Complete!

[Returns code for Claude to review]
```

---

## 🛡️ Safety Features

### **1. Retry Logic**
- Automatically retries up to 3 times on failure
- Exponential backoff between retries
- Prevents transient errors from breaking workflow

### **2. Timeout Protection**
- 60-second timeout per API call
- Prevents hanging on slow responses
- Clear error messages if timeout occurs

### **3. Usage Logging**
- All API calls logged with timestamps
- Token usage tracked
- Easy to monitor costs

### **4. Error Fallback**
- If GLM fails, Claude gets clear error message
- Can fall back to implementing itself
- No data loss

---

## 💡 Best Practices

### **1. Be Specific with Tasks**

Good:
```
✓ Use glm-implementation to create a user registration endpoint
  with email validation and password hashing using bcrypt
```

Bad:
```
✗ Use glm-implementation to handle user stuff
```

### **2. Provide Context**

```
✓ Use glm-implementation with these files:
  - services/auth.ts
  - types/user.ts

  Task: Add social login (Google, GitHub)
```

### **3. Let Claude Review**

After GLM returns code, Claude will:
- Check for security issues
- Validate error handling
- Ensure consistency with your codebase
- Add improvements if needed

### **4. Start Small**

First, test with simple tasks:
- Utility functions
- Validators
- Simple CRUD operations

Then move to more complex tasks once you trust the workflow.

---

## 🎛️ Configuration

### **Change GLM Model**

Edit the skill file and change:
```javascript
model: "glm-4.6"  // Change to "glm-4.7" if preferred
```

### **Adjust Token Limit**

```javascript
max_tokens: 4000  // Increase for longer implementations
```

### **Change Timeout**

```javascript
signal: AbortSignal.timeout(60000)  // 60 seconds in ms
```

---

## 🐛 Troubleshooting

### **Skill Not Found**

**Error:** "Skill glm-implementation not found"

**Solution:**
1. Check file exists: `C:\Users\tomjo\.claude\skills\glm-implementation.mjs`
2. Restart Claude: Exit and start again
3. Verify file syntax is correct

### **API Errors**

**Error:** "GLM API failed after 3 attempts"

**Possible causes:**
- Invalid API key
- Rate limiting (wait a few minutes)
- Network issues
- Z.ai service down

**Solution:**
- Check API key is valid
- Monitor usage: `Get-Content C:\Users\tomjo\.claude\glm-usage.log`
- Try again later if rate limited
- Check https://z.ai status page

### **Timeout Errors**

**Error:** "GLM API timeout after 60 seconds"

**Solution:**
- Task might be too complex for GLM
- Break it into smaller tasks
- Implement manually with Claude

---

## 📚 Example Workflows

### **Workflow 1: Feature Implementation**

```
You: We need to add password reset functionality

Claude: [Plans the approach]
     I'll delegate the implementation to GLM...

[GLM creates the code]

Claude: [Reviews and refines]
     Here's the complete implementation with proper error handling...

You: [Gets quality code, saved time]
```

### **Workflow 2: Test Generation**

```
You: Write unit tests for the payment service

Claude: [Understands what needs testing]
     I'll delegate test creation to GLM...

[GLM writes tests]

Claude: [Reviews test coverage]
     I'll add edge case tests for...
```

### **Workflow 3: Boilerplate Code**

```
You: Create CRUD operations for the product catalog

Claude: [Delegates repetitive CRUD to GLM]
     [GLM generates standard patterns]

Claude: [Adds business logic validation]
```

---

## 🎯 Success Indicators

You'll know it's working when:

1. ✅ **Claude volunteers to use it** for appropriate tasks
2. ✅ **Implementation code comes back** quickly
3. ✅ **Claude reviews and refines** the code
4. ✅ **Your subscription lasts longer** (less token usage)
5. ✅ **Quality stays high** (Claude is reviewing)
6. ✅ **Logs show usage** without errors

---

## 🔄 Maintenance

### **Weekly Checks**

```powershell
# Check usage for the week
Get-Content C:\Users\tomjo\.claude\glm-usage.log | Select-String -Pattern "$(Get-Date -Format 'yyyy-MM-dd')"

# Count total calls
(Get-Content C:\Users\tomjo\.claude\glm-usage.log).Count
```

### **Monthly Review**

- Check if skill is being used appropriately
- Review token usage and costs
- Adjust guidelines in CLAUDE.md if needed
- Update skill if new features needed

---

## 📝 Quick Reference Card

**File:** `C:\Users\tomjo\.claude\skills\glm-implementation.mjs`

**Usage:**
```
Use glm-implementation to [task]
Use glm-implementation with context: [context] for [task]
```

**Parameters:**
- `task` (required): What to implement
- `context` (optional): Additional information
- `files` (optional): List of affected files

**Logs:** `C:\Users\tomjo\.claude\glm-usage.log`

**Test:** `C:\dev\test-glm-skill.bat`

---

## ✅ Ready to Use!

Your skill is now:
- ✅ Created and configured
- ✅ Tested with API
- ✅ Logging enabled
- ✅ Error handling in place
- ✅ Documentation complete

**Start using it:** `claude`

Then: "Use glm-implementation to create [your task]"
