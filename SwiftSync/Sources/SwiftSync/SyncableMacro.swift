@attached(extension, conformances: SyncModelable, names: named(SyncID), named(syncIdentity), named(syncIdentityRemoteKeys), named(syncDefaultRefreshModelTypes), named(syncRelatedModelType), named(syncRelationshipSchemaDescriptors), named(_syncMake), named(_syncApply), named(_syncApplyRelationships), named(syncApplyGeneratedRelationships), named(_syncExportObject), named(syncMarkChanged))
public macro Syncable() = #externalMacro(module: "MacrosImplementation", type: "SyncableMacro")

@attached(peer)
public macro PrimaryKey(remote: String? = nil) = #externalMacro(module: "MacrosImplementation", type: "PrimaryKeyMacro")

@attached(peer)
public macro NotExport() = #externalMacro(module: "MacrosImplementation", type: "NotExportMacro")

@attached(peer)
public macro RemoteKey(_ key: String) = #externalMacro(module: "MacrosImplementation", type: "RemoteKeyMacro")
