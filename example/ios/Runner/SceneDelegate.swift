import Flutter
import UIKit
import MSAL

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    super.scene(scene, openURLContexts: URLContexts)

    for urlContext in URLContexts {
      MSALPublicClientApplication.handleMSALResponse(
        urlContext.url,
        sourceApplication: urlContext.options.sourceApplication
      )
    }
  }
}