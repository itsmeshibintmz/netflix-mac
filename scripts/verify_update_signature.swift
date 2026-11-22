import CryptoKit
import Foundation

do {
    guard CommandLine.arguments.count == 4,
          let signature = Data(base64Encoded: CommandLine.arguments[2]),
          let publicKeyData = Data(base64Encoded: CommandLine.arguments[3]) else {
        throw NSError(domain: "UpdateSignature", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Expected an archive path, base64 signature, and base64 public key."
        ])
    }
    let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKeyData)
    let archive = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]), options: .mappedIfSafe)
    guard publicKey.isValidSignature(signature, for: archive) else {
        throw NSError(domain: "UpdateSignature", code: 2, userInfo: [
            NSLocalizedDescriptionKey: "Update signature does not match the archive and configured public key."
        ])
    }
    print("Update signature verified.")
} catch {
    FileHandle.standardError.write(Data("\(error.localizedDescription)\n".utf8))
    exit(1)
}
