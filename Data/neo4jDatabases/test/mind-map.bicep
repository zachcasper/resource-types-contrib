extension radius
extension radiusResources

param environment string

resource mindMap 'Applications.Core/applications@2023-10-01-preview' = {
  name: 'mind-map'
  properties: {
    environment: environment
  }
}

resource graphDb 'Radius.Data/neo4jDatabases@2025-09-11-preview' = {
  name: 'graph-db'
  properties: {
    environment: environment
    application: mindMap.id
  }
}
