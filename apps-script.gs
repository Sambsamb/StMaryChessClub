// Google Apps Script for Chess Training Signup Form
// This script receives form data and stores it in a Google Sheet

// IMPORTANT: Update this with your actual spreadsheet ID
const SPREADSHEET_ID = '1JqwCtagwSRMH7V9XNZ7epjxPj5FFczlMeM6cr3gX9Rs';

function doPost(e) {
  try {
    let data;
    
    // Handle both regular JSON and no-cors mode requests
    if (e.postData && e.postData.contents) {
      data = JSON.parse(e.postData.contents);
    } else if (e.postData) {
      // Try getDataAsString for no-cors requests
      const rawData = e.postData.getBlob().getDataAsString();
      data = JSON.parse(rawData);
    } else {
      throw new Error('No postData received');
    }
    
    Logger.log('Received data: ' + JSON.stringify(data));
    
    // Get the active spreadsheet and sheet
    const spreadsheet = SpreadsheetApp.openById(SPREADSHEET_ID);
    let sheet = spreadsheet.getSheetByName('St Mary Coptic Orthodox Church of Delaware 2026 Chess Training Signup');
    
    // If sheet doesn't exist, create it with headers
    if (!sheet) {
      sheet = spreadsheet.insertSheet('St Mary Coptic Orthodox Church of Delaware 2026 Chess Training Signup');
      const headers = ['Timestamp', 'Name', 'Grade', 'Email', 'Phone'];
      sheet.appendRow(headers);
    }
    
    // Append the new row with form data
    const newRow = [
      data.timestamp || new Date().toISOString(),
      data.name || '',
      data.grade || '',
      data.email || '',
      data.phone || ''
    ];
    
    sheet.appendRow(newRow);
    Logger.log('Row appended successfully');
    
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
