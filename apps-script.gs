// Google Apps Script for Chess Training Signup Form
// This script receives form data and stores it in a Google Sheet

// IMPORTANT: Update this with your actual spreadsheet ID
const SPREADSHEET_ID = 'YOUR_SPREADSHEET_ID';

function doPost(e) {
  try {
    // Parse the JSON data from the form
    const data = JSON.parse(e.postData.contents);
    
    // Get the active spreadsheet and sheet
    const spreadsheet = SpreadsheetApp.openById(SPREADSHEET_ID);
    let sheet = spreadsheet.getSheetByName('Signups');
    
    // If sheet doesn't exist, create it with headers
    if (!sheet) {
      sheet = spreadsheet.insertSheet('Signups');
      const headers = ['Timestamp', 'Name', 'Grade', 'Email', 'Phone'];
      sheet.appendRow(headers);
    }
    
    // Append the new row with form data
    const newRow = [
      data.timestamp || new Date().toISOString(),
      data.name,
      data.grade,
      data.email,
      data.phone
    ];
    
    sheet.appendRow(newRow);
    
    // Return success response
    return ContentService.createTextOutput(JSON.stringify({
      status: 'success',
      message: 'Data received and stored'
    })).setMimeType(ContentService.MimeType.JSON);
    
  } catch (error) {
    // Log error and return error response
    Logger.log('Error: ' + error.toString());
    return ContentService.createTextOutput(JSON.stringify({
      status: 'error',
      message: error.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

// Helper function to test the script (optional)
function testScript() {
  const testData = {
    timestamp: new Date().toISOString(),
    name: 'John Smith',
    grade: '5',
    email: 'john@example.com',
    phone: '(555) 123-4567'
  };
  
  const payload = JSON.stringify(testData);
  const options = {
    method: 'post',
    payload: payload,
    headers: {
      'Content-Type': 'application/json'
    }
  };
  
  const response = UrlFetchApp.fetch(ScriptApp.getService().getUrl(), options);
  Logger.log(response.getContentText());
}
