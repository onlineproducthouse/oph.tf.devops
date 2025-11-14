output "scripts" {
  value = {
    for script in local.scripts : script.name => {
      key            = script.key,
      name           = script.name,
      etag           = filemd5(script.source_path),
      content_base64 = filebase64(script.source_path),
    }
  }
}
