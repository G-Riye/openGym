import { readFileSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { X509Certificate, randomUUID } from 'node:crypto'

const [certificatePath, outputDirectory] = process.argv.slice(2)
if (!certificatePath || !outputDirectory) throw new Error('Usage: make-iphone-profile.mjs <root.crt> <output-directory>')
const certificate = new X509Certificate(readFileSync(certificatePath))
if (!certificate.ca || !certificate.checkIssued(certificate) || !certificate.verify(certificate.publicKey)) {
  throw new Error('Expected the existing self-signed local CA certificate.')
}
const identifier = 'local.opengym.certificate.' + certificate.fingerprint256.replaceAll(':', '').toLowerCase()
const derBase64 = certificate.raw.toString('base64').match(/.{1,64}/g).join('\n')
const profile = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>PayloadType</key><string>Configuration</string>
  <key>PayloadVersion</key><integer>1</integer>
  <key>PayloadIdentifier</key><string>${identifier}</string>
  <key>PayloadUUID</key><string>${randomUUID().toUpperCase()}</string>
  <key>PayloadDisplayName</key><string>openGym Local Root</string>
  <key>PayloadOrganization</key><string>openGym on this PC</string>
  <key>PayloadDescription</key><string>安装这台电脑生成的 openGym 本机根证书，用于验证 openGym 的 HTTPS 连接。安装后仍需在证书信任设置中手动开启完全信任。</string>
  <key>TargetDeviceType</key><integer>1</integer>
  <key>PayloadContent</key>
  <array>
    <dict>
      <key>PayloadType</key><string>com.apple.security.root</string>
      <key>PayloadVersion</key><integer>1</integer>
      <key>PayloadIdentifier</key><string>${identifier}.root</string>
      <key>PayloadUUID</key><string>${randomUUID().toUpperCase()}</string>
      <key>PayloadDisplayName</key><string>openGym Local Root</string>
      <key>PayloadCertificateFileName</key><string>openGym-root.cer</string>
      <key>PayloadContent</key>
      <data>
${derBase64}
      </data>
    </dict>
  </array>
</dict>
</plist>
`
writeFileSync(join(outputDirectory, 'openGym-root.cer'), certificate.raw)
writeFileSync(join(outputDirectory, 'openGym-iphone.mobileconfig'), profile, 'utf8')
process.stdout.write(certificate.fingerprint256)
