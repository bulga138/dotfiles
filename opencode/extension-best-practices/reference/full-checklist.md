# 🧾 Browser Extension Best Practices — Complete Checklist (104 Points)

## Table of Contents

1. [Manifest V3 & Platform Compliance](#-1-manifest-v3--platform-compliance) — Items 1–10
2. [Security](#-2-security) — Items 11–27
3. [Privacy](#-3-privacy) — Items 28–33
4. [Performance & Stability](#-4-performance--stability) — Items 34–47
5. [User Experience (UX)](#-5-user-experience-ux) — Items 48–64
6. [Store Listing](#-6-store-listing) — Items 65–83
7. [Updates & Maintenance](#-7-updates--maintenance) — Items 84–98
8. [Cross-Browser & Publishing](#-8-cross-browser--publishing) — Items 99–104

---

## 📁 1. Manifest V3 & Platform Compliance

### 1.1 Manifest Version

- [ ] **1. Use Manifest V3** — All new extensions must use Manifest V3. V2 is no longer supported for new submissions.
- [ ] **2. Set `manifest_version` to 3** — The manifest.json must explicitly declare `"manifest_version": 3`.
- [ ] **3. Do not add new features during migration** — When migrating from V2 to V3, avoid adding new functionality to reduce unexpected issues.

### 1.2 Service Worker (Background Scripts)

- [ ] **4. Replace background pages with a service worker** — V3 requires a service worker instead of a background or event page.
- [ ] **5. Keep background code off the main thread** — Service workers ensure background code doesn't hurt performance.
- [ ] **6. Move DOM/Window API calls to offscreen documents** — Service workers cannot access DOM or window APIs; use offscreen documents instead.

### 1.3 Remote Code Restrictions

- [ ] **7. No remotely hosted code** — Extensions may only execute JavaScript included in their own package.
- [ ] **8. Full functionality must be discernible from submitted code** — The extension's complete functionality must be clear from its submitted code.

### 1.4 Host Permissions

- [ ] **9. Use `host_permissions` separately** — In V3, host permissions must be declared in a separate `host_permissions` field.
- [ ] **10. Specify minimum Chrome version if needed** — If using newer APIs, set `minimum_chrome_version` in the manifest.

---

## 🔒 2. Security

### 2.1 Permissions (Least Privilege)

- [ ] **11. Request only the minimal set of permissions** — Only declare permissions essential for core functionality.
- [ ] **12. Avoid broad host permissions** — Don't request `"<all_urls>"` unless absolutely necessary.
- [ ] **13. Don't copy-paste manifest permissions blindly** — Review your manifest to ensure you only declare what you need.
- [ ] **14. Use `activeTab` when possible** — Prefer `activeTab` permission for access only when the user interacts with the extension.
- [ ] **15. Use optional permissions** — Request permissions at runtime only when needed using the `chrome.permissions` API.
- [ ] **16. Don't request unnecessary API permissions** — For example, you don't need the `tabs` permission if only using `chrome.tabs.create`.

### 2.2 Content Security Policy (CSP)

- [ ] **17. Set a restrictive CSP in the manifest** — Use `"content_security_policy"` to control where scripts can execute.
- [ ] **18. Use `default-src 'self'`** — Specify that the extension loads resources only from its own package.
- [ ] **19. Never use `eval()`** — Avoid `eval()` and similar functions that execute arbitrary strings.
- [ ] **20. Never use `innerHTML` or `document.write()`** — These can introduce XSS vulnerabilities.

### 2.3 Network & Data Security

- [ ] **21. Always use HTTPS for external resources** — Never load scripts or resources over HTTP.
- [ ] **22. Transmit user data securely** — Use HTTPS or other secure mechanisms for all user data transmission.
- [ ] **23. Avoid man-in-the-middle (MITM) attacks** — Loading scripts over HTTP opens your extension to MITM attacks.

### 2.4 Code Quality

- [ ] **24. Use secure coding practices** — Follow secure coding standards throughout development.
- [ ] **25. Avoid third-party libraries with known vulnerabilities** — Vet all dependencies for security issues.
- [ ] **26. Never use deceptive installation tactics** — Don't mislead users into installing your extension.
- [ ] **27. Don't transmit malware or malicious content** — Extensions must not contain viruses, worms, or Trojan horses.

---

## 🔐 3. Privacy

- [ ] **28. Disclose all data collection in the "Privacy" tab** — Clearly state what user data is collected and how it's used.
- [ ] **29. Keep privacy disclosures accurate and up to date** — Privacy information must remain current.
- [ ] **30. Obtain explicit user consent for data collection** — Users must consent to any data collection or usage.
- [ ] **31. Avoid tracking or fingerprinting without consent** — Do not track or fingerprint users without explicit permission.
- [ ] **32. Comply with additional policies for sensitive data** — Financial, health, or personal information requires extra compliance.
- [ ] **33. Publish a privacy policy** — Make your privacy policy available and link it in your store listing.

---

## ⚡ 4. Performance & Stability

- [ ] **34. Minimize background activity** — Reduce background processing to save resources.
- [ ] **35. Minimize memory usage** — Avoid excessive memory consumption.
- [ ] **36. Avoid crashes, freezes, and excessive CPU consumption** — Ensure stability across all usage scenarios.
- [ ] **37. Test across different browser versions** — Test on multiple versions of your target browser(s).
- [ ] **38. Test across supported operating systems** — Ensure compatibility across platforms.
- [ ] **39. Add end-to-end tests** — Use testing libraries like Puppeteer for comprehensive testing.
- [ ] **40. Perform manual testing** — Test under various network conditions and scenarios.
- [ ] **41. Test for crashes and broken features before submission** — Always test prior to publishing.
- [ ] **42. For Firefox, test on Nightly and Beta releases** — Ensure upcoming changes don't break your extension.
- [ ] **43. Avoid writing slow CSS** — Optimize CSS for performance.
- [ ] **44. Avoid DOM mutation event listeners** — These can degrade performance.
- [ ] **45. Lazily load services** — Load resources only when needed.

### 4.6 Storage

- [ ] **46. Use the correct Storage API** — Differentiate between `chrome.storage.local` (large data), `chrome.storage.sync` (synced across devices, small limits), and `chrome.storage.session` (in-memory, MV3 specific).
- [ ] **47. Handle storage rate limits** — Batch your updates to `chrome.storage.sync` to avoid hitting strict per-minute/hour quota limits.

---

## 🎨 5. User Experience (UX)

### 5.1 Core Design Principles

- [ ] **48. Focus on a single core function** — Extensions work best when centered around one main use case.
- [ ] **49. Communicate purpose in three sentences or less** — You should be able to describe your extension succinctly.
- [ ] **50. Provide a clean, intuitive, and responsive interface** — Make the UI easy to use.
- [ ] **51. Avoid disruptive ads, pop-ups, or misleading prompts** — Don't annoy or deceive users.
- [ ] **52. Integrate seamlessly into the browsing experience** — The extension should feel native to the browser.

### 5.2 UI Component Selection

- [ ] **53. Use a toolbar button for features usable on most websites** — Browser actions are for general-purpose features.
- [ ] **54. Use an address bar button for features specific to certain pages** — Page actions are for domain- or page-type-specific features.
- [ ] **55. Use a sidebar for features requiring parallel actions** — Sidebars are for information or actions needed while viewing pages.
- [ ] **56. Add a popup to buttons when offering multiple features** — Popups provide a door-hanger interface for additional options.

### 5.3 Onboarding & Persistent Interfaces

- [ ] **57. Provide screenshots and videos in your listing** — Help users understand how the extension works before installing.
- [ ] **58. Design persistent interfaces to minimize distraction** — Sidebars and other persistent UIs should be helpful, not intrusive.
- [ ] **59. Create a good onboarding experience** — Guide new users through setup and initial use.
- [ ] **60. Keep onboarding design consistent** — Use consistent icons and colors with your listing and website.

### 5.4 Firefox-Specific UX

- [ ] **61. Be "Firefoxy" in look and feel** — Follow Firefox design conventions for native integration.

### 5.5 Accessibility & Localization

- [ ] **62. Support keyboard navigation** — Ensure popups, sidebars, and options pages are fully navigable via `Tab` and `Enter` keys.
- [ ] **63. Use ARIA labels** — Make sure custom UI elements are readable by screen readers.
- [ ] **64. Support Internationalization (i18n)** — Use the `_locales` directory and `chrome.i18n` API to localize your store listing and extension UI for a global audience.

---

## 📝 6. Store Listing

### 6.1 Title, Summary & Description

- [ ] **65. Make the title clear, descriptive, and concise** — Users should understand the extension from the title alone.
- [ ] **66. Make the title unique** — Avoid titles too similar to existing extensions.
- [ ] **67. Don't stuff the title with keywords** — Short, catchy names are more memorable.
- [ ] **68. Write a concise summary (132 characters or less)** — This appears in search results and category pages.
- [ ] **69. Highlight features that resonate with your audience** — Focus on what matters most to users.
- [ ] **70. Avoid generic or superlative descriptions** — Don't use "best extension ever" or "greatest".
- [ ] **71. Write a detailed, informative description** — Go beyond one sentence; use an overview paragraph followed by feature list.
- [ ] **72. Don't keyword-stuff the description** — Repetitive keywords can lead to suspension.
- [ ] **73. Include detailed information in the "single purpose" field** — Clearly state the extension's primary functionality.

### 6.2 Images & Assets

- [ ] **74. Use high-quality screenshots that reflect the actual experience** — Show real usage, not mockups.
- [ ] **75. Annotate key features in screenshots** — Help users understand what they're seeing.
- [ ] **76. Show the extension in action with realistic data** — Demonstrate key features with real-world examples.
- [ ] **77. Use a high-quality store icon** — Follow extension icon best practices.

### 6.3 General Listing Requirements

- [ ] **78. Keep all listing information up to date and accurate** — This includes metadata, category, and data collection certifications.
- [ ] **79. Verify your contact information is correct** — Ensure you receive important communications from the store.
- [ ] **80. Provide meaningful customer support** — Be responsive to user inquiries.
- [ ] **81. Extensions should add value to the store** — If not useful or unique, it doesn't belong.
- [ ] **82. Don't cheat or scam the system** — No misleading users, circumventing enforcement, copying others, or manipulating reviews.
- [ ] **83. Stay informed about policy changes** — Google may update policies; monitor your email for announcements.

---

## 🔄 7. Updates & Maintenance

- [ ] **84. Create a roadmap of features** — Plan updates based on user feedback and new browser releases.
- [ ] **85. Update on a regular cycle** — Monthly or quarterly updates are recommended.
- [ ] **86. Avoid too-frequent updates** — Daily or weekly updates can be disruptive to users.
- [ ] **87. Include an "upboarding" page with update details** — Describe improvements; don't just say "bug fixes and improvements".
- [ ] **88. Provide a deprecation period when removing features** — Give users at least one upgrade cycle notice before removing features.
- [ ] **89. Provide guided instructions for replaced features** — Retain old menu items that guide users to new features.
- [ ] **90. Balance bug fixes with new features** — Users notice if bugs aren't addressed.
- [ ] **91. Consider silent releases for non-user-facing fixes** — Technical fixes with no user impact can be released without an upboarding page.
- [ ] **92. Update your store listing with each release** — Include release notes, update description, replace screenshots, and consider tweaking the icon.
- [ ] **93. Announce updates through your channels** — Use website, social media, and user groups.
- [ ] **94. Monitor ratings, reviews, and feedback after each release** — Watch for unexpected issues.
- [ ] **95. Respond constructively to user feedback** — Address bugs and usability issues promptly.
- [ ] **96. Respond promptly to flagged security issues** — Address any security concerns quickly.
- [ ] **97. Regularly read new Chrome/Microsoft/Firefox release notes** — Stay current with platform changes.
- [ ] **98. Set an uninstall URL** — Use `chrome.runtime.setUninstallURL()` to redirect users to a polite, short survey when they remove your extension to gather feedback on why they left.

---

## 🌐 8. Cross-Browser & Publishing

- [ ] **99. For Firefox, ensure your extension is signed** — Extensions must be signed to install in Firefox.
- [ ] **100. Use the WebExtensions API for cross-browser compatibility** — Firefox extensions are built using WebExtensions API.
- [ ] **101. Test your extension in Firefox if porting from Chrome** — Most Chrome extensions run in Firefox with few changes.
- [ ] **102. Upload your .crx file to the Developer Hub for validation** — Check Firefox compatibility by uploading your extension.
- [ ] **103. Automate your build process** — Use modern bundlers (like Vite, Webpack, or framework-specific tools like WXT) to handle manifest generation, asset moving, and code minification.
- [ ] **104. Implement CI/CD for publishing** — Consider using CLI tools to automate zipping and uploading to the Chrome Web Store and Firefox Add-ons (AMO) to avoid manual packaging errors.
