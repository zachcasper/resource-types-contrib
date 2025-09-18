extension radius
extension radiusResources

param environment string

resource testApp 'Applications.Core/applications@2023-10-01-preview' = {
  name: 'testapp'
  properties: {
    environment: environment
  }
}

resource testSecret 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'testsecret'
  properties: {
    environment: environment
    application: testApp.id
    data: {
      stringData: {
        value: 'this is a string'
      }
      encodedData: {
        value: 'dGhpcyBpcyBhIHN0cmluZw=='
        encoding: 'base64'
      }
    }
  }
}
