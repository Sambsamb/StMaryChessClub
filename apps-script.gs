// Google Apps Script for Chess Training Signup Form
// This script receives form data and stores it in a Google Sheet

// IMPORTANT: Update this with your actual spreadsheet ID
const SPREADSHEET_ID = '1E4EfvNni-Qkpg149f5tCqFFK6-P8gnIcxgbfxiRuh2I';

function doPost(e) {
  try {
    Logger.log('Request received. Parameters: ' + JSON.stringify(e.parameter));
    
    // Get form parameters (from FormData)
    const name = e.parameter.name || '';
    const grade = e.parameter.grade || '';
    const email = e.parameter.email || '';
    const phone = e.parameter.phone || '';
    const timestamp = e.parameter.timestamp || new Date().toISOString();
    
    Logger.log('Received data - Name: ' + name + ', Grade: ' + grade + ', Email: ' + email);
    
    // Get the active spreadsheet and sheet
    const spreadsheet = SpreadsheetApp.openById(SPREADSHEET_ID);
    let sheet = spreadsheet.getSheetByName('St Mary Coptic Orthodox Church of Delaware 2026 Chess Training Signup');
    
    // If sheet doesn't exist, create it with headers
    if (!sheet) {
      sheet = spreadsheet.insertSheet('St Mary Coptic Orthodox Church of Delaware 2026 Chess Training Signup');
      const headers = ['Timestamp', 'Name', 'Grade', 'Email', 'Phone'];
      sheet.appendRow(headers);
      Logger.log('Created new sheet with headers');
    }
    
    // Append the new row with form data
    const newRow = [timestamp, name, grade, email, phone];
    sheet.appendRow(newRow);
    Logger.log('Row appended successfully');
    
    // Return success response
    return ContentService.createTextOutput('Success');
    
  } catch (error) {
    // Log error and return error response
    Logger.log('Error: ' + error.toString());
    return ContentService.createTextOutput('Error: ' + error.toString());
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
