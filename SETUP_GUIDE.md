# Chess Training Signup Form - Google Sheets Integration Setup

## Overview
This guide walks you through setting up the signup form to automatically save responses to a Google Sheet.

## Setup Steps

### Step 1: Create a Google Sheet
1. Go to [Google Sheets](https://sheets.google.com)
2. Create a new spreadsheet titled "Chess Training Signups"
3. Copy the **Spreadsheet ID** from the URL:
   - URL format: `https://docs.google.com/spreadsheets/d/YOUR_SPREADSHEET_ID/edit`
   - The ID is the long string between `/d/` and `/edit`

### Step 2: Create a Google Apps Script
1. In your Google Sheet, go to **Tools** → **Script Editor**
2. Delete any default code
3. Copy and paste the entire contents of `apps-script.gs` file
4. On line 4, replace `'YOUR_SPREADSHEET_ID'` with your actual Spreadsheet ID:
   ```javascript
   const SPREADSHEET_ID = '1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s0t';
   ```
5. Save the script (Ctrl+S)
6. Give the project a name when prompted (e.g., "Chess Signup Handler")

### Step 3: Deploy as Web App
1. In Apps Script, click **Deploy** → **New deployment**
2. Select type: **Web App**
3. Configure as follows:
   - **Execute as:** Your Google account
   - **Who has access:** Anyone
4. Click **Deploy**
5. A dialog will appear asking for permissions:
   - Click **Authorize access**
   - Select your Google account
   - Click **Allow** when prompted about app permissions
6. Copy the **Deployment URL** that appears (looks like: `https://script.google.com/macros/d/YOUR_SCRIPT_ID/usercontent`)

### Step 4: Update the HTML Form
1. Open `signup.html` in a text editor
2. Find this line (around line 102):
   ```javascript
   const GOOGLE_APPS_SCRIPT_URL = 'https://script.google.com/macros/d/YOUR_SCRIPT_ID/usercontent';
   ```
3. Replace `YOUR_SCRIPT_ID` with the Deployment URL from Step 3
4. Save the file

### Step 5: Test the Form
1. Open `signup.html` in a web browser
2. Fill out the form and submit
3. Go back to your Google Sheet and refresh - you should see the data in the "Signups" sheet!

## Features
- ✅ Automatically creates "Signups" sheet if it doesn't exist
- ✅ Adds headers on first use
- ✅ Records timestamp of each submission
- ✅ Stores: Name, Grade, Email, Phone

## Troubleshooting

**Form submits but data doesn't appear in Google Sheet:**
- Check that the Deployment URL is correct in signup.html
- Verify the Spreadsheet ID matches in apps-script.gs
- Check the Apps Script logs (Tools → Logs) for error messages

**Getting a permission error:**
- Make sure you authorized the Apps Script to access your Google Sheet
- The script must be deployed with "Who has access: Anyone"

**Script not executing:**
- Check that you saved the Apps Script file (Ctrl+S)
- Verify you completed the deployment steps

## Security Notes
- The form currently accepts submissions from anyone
- To restrict submissions, you can modify the Apps Script to check email domains or add authentication
- Contact information is stored in a Google Sheet - ensure you follow appropriate privacy/security practices

## File Structure
```
StMaryChessClub/
├── signup.html              # The signup form (update the URL here)
├── apps-script.gs           # Google Apps Script code
└── SETUP_GUIDE.md          # This file
```
