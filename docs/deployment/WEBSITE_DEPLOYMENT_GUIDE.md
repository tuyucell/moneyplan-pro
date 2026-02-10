# Website Deployment Guide - GitHub Pages + Cloudflare

## 📋 Overview

This guide will help you deploy your website to GitHub Pages and configure a custom domain with Cloudflare DNS management.

## 🚀 Step 1: GitHub Repository Setup

### 1.1 Create GitHub Repository

1. Go to [GitHub](https://github.com) and sign in
2. Click the "+" icon → "New repository"
3. Repository name: `invest-guide-app` (or your preferred name)
4. Choose Public or Private (GitHub Pages works with both for paid accounts)
5. **DO NOT** initialize with README (we already have code)
6. Click "Create repository"

### 1.2 Push Code to GitHub

```bash
cd /Users/turgayyucel/invest-guide-app

# Initialize git (if not already done)
git init

# Add all files
git add .

# Commit
git commit -m "Initial commit: App + Website"

# Add remote (replace USERNAME and REPO_NAME)
git remote add origin https://github.com/USERNAME/REPO_NAME.git

# Push to GitHub
git branch -M main
git push -u origin main
```

**Important:** Make sure `.gitignore` is working correctly. Verify that `android/key.properties` and `*.jks` files are NOT pushed!

```bash
# Check what will be pushed
git status

# If you see key.properties or .jks files, they should NOT be there!
```

## 🌐 Step 2: GitHub Pages Configuration

### 2.1 Enable GitHub Pages

1. Go to your repository on GitHub
2. Click "Settings" tab
3. Scroll down to "Pages" in the left sidebar
4. Under "Source":
   - Branch: `main`
   - Folder: `/website` (or `/docs` if you move files there)
5. Click "Save"

### 2.2 Wait for Deployment

- GitHub will start building your site
- This takes 2-5 minutes
- You'll see a green checkmark when ready
- Your site will be at: `https://USERNAME.github.io/REPO_NAME/`

### 2.3 Test Your Site

Visit your GitHub Pages URL and verify:
- [ ] Home page loads correctly
- [ ] Privacy Policy page works
- [ ] Terms of Service page works
- [ ] KVKK page works
- [ ] All images load
- [ ] Theme switcher works
- [ ] Language switcher works

## 🌍 Step 3: Domain Purchase

### 3.1 Choose a Domain Name

Suggestions:
- `investguide.app` (premium, ~$20/year)
- `yatirimrehberi.com` (~$12/year)
- `moneyplanpro.com` (~$12/year)
- Or your own creative name!

### 3.2 Where to Buy

**Option A: Cloudflare Registrar (Recommended)**
- Pros: At-cost pricing, automatic DNS setup, no markup
- Cons: Limited TLDs available
- URL: https://www.cloudflare.com/products/registrar/

**Option B: Namecheap**
- Pros: Wide selection, good prices, easy to use
- Cons: Need to manually update nameservers
- URL: https://www.namecheap.com

**Option C: GoDaddy**
- Pros: Popular, good support
- Cons: More expensive, aggressive upselling
- URL: https://www.godaddy.com

### 3.3 Purchase Domain

1. Search for your desired domain
2. Add to cart
3. Complete purchase
4. **Save your login credentials!**

## ☁️ Step 4: Cloudflare Setup

### 4.1 Create Cloudflare Account

1. Go to [Cloudflare](https://www.cloudflare.com)
2. Sign up for a free account
3. Verify your email

### 4.2 Add Your Domain to Cloudflare

1. Click "Add a Site"
2. Enter your domain name (e.g., `investguide.app`)
3. Click "Add Site"
4. Select the **Free** plan
5. Click "Continue"

### 4.3 Update Nameservers

Cloudflare will show you 2 nameservers like:
```
ns1.cloudflare.com
ns2.cloudflare.com
```

**Go to your domain registrar** (where you bought the domain):

**If Namecheap:**
1. Go to Domain List → Manage
2. Find "Nameservers" section
3. Select "Custom DNS"
4. Enter Cloudflare's nameservers
5. Save

**If GoDaddy:**
1. Go to My Products → Domains
2. Click DNS next to your domain
3. Scroll to "Nameservers"
4. Click "Change"
5. Select "Custom"
6. Enter Cloudflare's nameservers
7. Save

**Wait for propagation:** 2-48 hours (usually 2-6 hours)

### 4.4 Verify Nameservers

In Cloudflare, click "Done, check nameservers"

You can check status with:
```bash
dig NS yourdomain.com
# or
nslookup -type=NS yourdomain.com
```

## 🔧 Step 5: DNS Configuration in Cloudflare

### 5.1 Add DNS Records

Once nameservers are active, add these DNS records in Cloudflare:

**A Records (for root domain):**

| Type | Name | Content | Proxy Status |
|------|------|---------|--------------|
| A | @ | 185.199.108.153 | Proxied (🧡) |
| A | @ | 185.199.109.153 | Proxied (🧡) |
| A | @ | 185.199.110.153 | Proxied (🧡) |
| A | @ | 185.199.111.153 | Proxied (🧡) |

**CNAME Record (for www):**

| Type | Name | Content | Proxy Status |
|------|------|---------|--------------|
| CNAME | www | USERNAME.github.io | Proxied (🧡) |

Replace `USERNAME` with your GitHub username.

### 5.2 Configure SSL/TLS

1. In Cloudflare, go to "SSL/TLS"
2. Set encryption mode to **"Full"** or **"Full (strict)"**
3. Enable "Always Use HTTPS"
4. Enable "Automatic HTTPS Rewrites"

### 5.3 Additional Cloudflare Settings (Optional but Recommended)

**Security:**
- Go to "Security" → "Settings"
- Set Security Level to "Medium"
- Enable "Browser Integrity Check"

**Speed:**
- Go to "Speed" → "Optimization"
- Enable "Auto Minify" for HTML, CSS, JS
- Enable "Brotli" compression

**Caching:**
- Go to "Caching" → "Configuration"
- Set Browser Cache TTL to "4 hours" or "8 hours"

## 🔗 Step 6: GitHub Pages Custom Domain

### 6.1 Add Custom Domain in GitHub

1. Go to your repository on GitHub
2. Settings → Pages
3. Under "Custom domain", enter your domain: `yourdomain.com`
4. Click "Save"

### 6.2 Create CNAME File

GitHub will create a `CNAME` file in your repository. If it's in the wrong location, move it:

```bash
# If CNAME is in root, move it to website folder
mv CNAME website/CNAME

# Commit and push
git add website/CNAME
git commit -m "Move CNAME to website folder"
git push
```

### 6.3 Enable HTTPS

1. Wait 5-10 minutes for DNS to propagate
2. In GitHub Settings → Pages
3. Check "Enforce HTTPS"
4. If grayed out, wait a bit longer

## ✅ Step 7: Verification

### 7.1 Test Your Domain

Visit your domain in a browser:
- `https://yourdomain.com`
- `https://www.yourdomain.com`

Both should work and redirect to HTTPS.

### 7.2 Check SSL Certificate

Click the padlock icon in your browser. You should see:
- Cloudflare certificate
- Valid and trusted
- Green padlock

### 7.3 Test All Pages

- [ ] `https://yourdomain.com/` (home page)
- [ ] `https://yourdomain.com/privacy.html`
- [ ] `https://yourdomain.com/terms.html`
- [ ] `https://yourdomain.com/kvkk.html`
- [ ] `https://yourdomain.com/refund.html`

### 7.4 Test Responsiveness

- [ ] Test on mobile device
- [ ] Test on tablet
- [ ] Test on desktop
- [ ] Test theme switcher
- [ ] Test language switcher

## 🔄 Step 8: Update App Store Links

### 8.1 Update Website Content

Replace placeholder URLs in your website files:

```bash
# In website/index.html, privacy.html, terms.html, kvkk.html
# Replace:
[SUPPORT_EMAIL] → your-email@domain.com
[COMPANY_NAME] → Your Company Name
[COMPANY_ADDRESS] → Your Address
[PHONE_NUMBER] → Your Phone (optional)
[WEBSITE_URL] → https://yourdomain.com
[PRIVACY_POLICY_URL] → https://yourdomain.com/privacy.html
```

### 8.2 Update Privacy Policy and Terms

Edit the following files and replace all placeholders:
- `PRIVACY_POLICY.md`
- `TERMS_OF_SERVICE.md`
- `website/privacy.html`
- `website/terms.html`
- `website/kvkk.html`

### 8.3 Commit and Push

```bash
git add .
git commit -m "Update website with actual company information"
git push
```

Wait 2-5 minutes for GitHub Pages to rebuild.

### 8.4 Update App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Your App → App Information
3. Update:
   - Privacy Policy URL: `https://yourdomain.com/privacy.html`
   - Support URL: `https://yourdomain.com/`

### 8.5 Update Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Your App → Store Presence → Store Listing
3. Update:
   - Privacy Policy: `https://yourdomain.com/privacy.html`
   - Website: `https://yourdomain.com/`

## 🎯 Step 9: SEO and Analytics (Optional)

### 9.1 Add Google Analytics

1. Create Google Analytics account
2. Get tracking ID
3. Add to `website/index.html` before `</head>`:

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>
```

### 9.2 Add Google Search Console

1. Go to [Google Search Console](https://search.google.com/search-console)
2. Add property: `https://yourdomain.com`
3. Verify ownership (DNS or HTML file method)
4. Submit sitemap (if you create one)

### 9.3 Create Sitemap (Optional)

Create `website/sitemap.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://yourdomain.com/</loc>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://yourdomain.com/privacy.html</loc>
    <priority>0.8</priority>
  </url>
  <url>
    <loc>https://yourdomain.com/terms.html</loc>
    <priority>0.8</priority>
  </url>
  <url>
    <loc>https://yourdomain.com/kvkk.html</loc>
    <priority>0.8</priority>
  </url>
</urlset>
```

## 🐛 Troubleshooting

### Issue: "404 Not Found" on GitHub Pages

**Solution:**
- Check that `/website` folder exists in your repo
- Verify GitHub Pages source is set to `/website` folder
- Wait 5 minutes and try again
- Check GitHub Actions tab for build errors

### Issue: Custom domain not working

**Solution:**
- Verify DNS records are correct
- Check nameservers are pointing to Cloudflare
- Wait for DNS propagation (up to 48 hours)
- Clear browser cache
- Try incognito mode

### Issue: "Not Secure" warning

**Solution:**
- Wait for SSL certificate to provision (10-30 minutes)
- Ensure "Enforce HTTPS" is enabled in GitHub Pages
- Check Cloudflare SSL/TLS mode is "Full"
- Clear browser cache

### Issue: Images not loading

**Solution:**
- Check image paths are correct (relative paths)
- Verify images are in `website/assets/images/` folder
- Check file names match exactly (case-sensitive)
- Hard refresh browser (Cmd+Shift+R or Ctrl+Shift+R)

### Issue: DNS not propagating

**Check DNS status:**
```bash
# Check A records
dig yourdomain.com

# Check CNAME
dig www.yourdomain.com

# Check nameservers
dig NS yourdomain.com

# Online tool
# Visit: https://dnschecker.org
```

## 📞 Support Resources

- **GitHub Pages Docs:** https://docs.github.com/en/pages
- **Cloudflare Docs:** https://developers.cloudflare.com
- **DNS Checker:** https://dnschecker.org
- **SSL Checker:** https://www.sslshopper.com/ssl-checker.html

## ✅ Final Checklist

- [ ] GitHub repository created and code pushed
- [ ] GitHub Pages enabled and working
- [ ] Domain purchased
- [ ] Cloudflare account created
- [ ] Nameservers updated at registrar
- [ ] DNS records added in Cloudflare
- [ ] SSL/TLS configured
- [ ] Custom domain added to GitHub Pages
- [ ] HTTPS enforced
- [ ] All pages accessible via custom domain
- [ ] Company information updated in all legal pages
- [ ] App Store Connect URLs updated
- [ ] Google Play Console URLs updated
- [ ] Website tested on multiple devices
- [ ] SSL certificate valid

**Congratulations! Your website is now live! 🎉**
