# Diagnóstico diferencial y restauración de autenticación

## Conclusión corregida

El error `-42011` de la prueba aislada **no demostraba incompatibilidad de OmniTool**. La prueba omitía un parámetro que la aplicación real proporciona: `bypassRedirectURIValidation: true`. Original y modernizado ya transmitían este campo. Su valor predeterminado sigue siendo `false`; no se ha añadido un bypass ni un workaround.

Con los parámetros reales, la configuración original extraída de Git y la restaurada son equivalentes bajo **el mismo MSAL 2.0.0**. Ambos clientes nativos se construyen correctamente y el handler Flutter real devuelve inicialización satisfactoria. **No se ha ejecutado autenticación interactiva ni adquisición silenciosa contra Microsoft.** La compatibilidad integral de producción queda pendiente de esa validación.

## Evidencia de la aplicación real

Código localizado en `/Users/dinux/Documents/DEVELOP/origin/noe_macos`, HEAD `6495ce4`. La inicialización relevante está también en ese commit, no solo en el archivo de trabajo:

- `lib/app/data/provider/login/login_provider.dart:36–41`: usa `MSALPublicClientApplicationConfig` con los valores de `LoginConstants`, ambos redirects explícitos, autoridad explícita y **`bypassRedirectURIValidation: true`**.
- `lib/app/constants/app_constants.dart:140–151`: client ID, redirect y scope coinciden con los facilitados. No tenant ID.
- Bundle ID: `com.otis.es.schindlerSVT`, declarado en las configuraciones de Runner.
- Info.plist registra los tres esquemas indicados por el mantenedor, además de consultar `msauthv2` y `msauthv3`. No se ha modificado este archivo ni ninguno de la aplicación real.
- La aplicación configura `prefersEphemeralWebBrowserSession` después de inicializar; conserva el cliente según ese ajuste. Para adquisición silenciosa enumera cuentas y utiliza la primera con el scope empresarial original.
- El package_config local apunta al fork cacheado en el commit `b44c247`. El pubspec.lock de trabajo resuelve ese mismo commit; está modificado respecto al HEAD de OmniTool, por lo que no identifica necesariamente la dependencia del binario publicado.
- Los dos `Package.resolved` disponibles de OmniTool indican Apple MSAL **2.14.1**, revisión `6ec4d48696fc254f96e1be59f503251effa8b4a7`. El mantenedor confirma éxito con MSAL 2.0; esto no se contradice con una prueba de configuración distinta. No hay un binario publicado disponible para certificar su versión exacta. No se ha cambiado ninguna dependencia.

## Secuencia original y actual

Referencia original: último commit del plugin, `b44c247`. La clase registrada iOS `MsalFlutterPlugin` delega en `SwiftMsalFlutterPluginV2`.

1. Dart serializa `clientId`, `redirectUri`, `authority` y `bypassRedirectURIValidation` por el canal `msal_flutter`.
2. El puente analiza la autoridad mediante MSAL y construye `MSALPublicClientApplicationConfig` con el client ID y redirect explícitos.
3. Transfiere la opción de validación recibida; configura autoridades conocidas, caché y demás opciones.
4. Ejecuta `MSALPublicClientApplication(configuration:)` y guarda el cliente.
5. Resuelve el controlador de presentación, configura el webview y selecciona la primera cuenta de `allAccounts()` si existe.
6. Devuelve éxito; OmniTool configura la sesión web privada y solicita tokens usando el scope empresarial.

La secuencia restaurada conserva esos pasos. **El redirect nativo resuelto es el explícito `msal<client-id>://auth`; no se transforma a `msauth.<bundle-id>://auth`.** Ese segundo valor solo se genera cuando falta un redirect no vacío. Tanto el original como el actual hacen esta distinción.

## Causa de `-42011`

| Diferencia | Prueba anterior | OmniTool / prueba corregida |
| --- | --- | --- |
| Opción de validación | Omitida → `false` | Explícita → `true`, como en la aplicación existente |
| Bundle ID | `com.example.a` | `com.otis.es.schindlerSVT` |
| Esquemas de prueba | Esquema de ejemplo y un esquema añadido | Los tres esquemas reales |
| Autoridades conocidas antes de restaurar | Lista vacía | Autoridad explícita incluida, como en el original |
| Scope/client ID/redirect/authority | Valores facilitados | Los mismos valores, sin sustituciones |

Con `false`, MSAL entra en la comprobación de formato broker-capable para AAD/common y devuelve `MSALErrorDomain -50000`, código interno `-42011`. Con la opción existente de OmniTool, los constructores original y actual tienen éxito. La prueba diferencial incluye ambos casos y reproduce la diferencia; registrar esquemas por sí solo no explicaba el éxito de producción.

La opción encontrada es parte del contrato real del caller; no se activa automáticamente, ni se propone como solución nueva. No se ha implementado OAuth propio, cambiado la autoridad, añadido tenant ni eludido otras verificaciones de Microsoft.

## Cambios de comportamiento restaurados

- Autoridades conocidas: vuelve a incluir la autoridad explícita y anexar las entradas configuradas, como el original.
- Inicialización: vuelve a guardar el cliente antes de resolver el controlador y conserva la selección de cuenta original.
- Enumeración: vuelve a `allAccounts()` y actualiza la cuenta actual con la primera cuenta local; se elimina el cambio a cuentas del dispositivo/broker y filtros.
- Silent: vuelve a no aplicar la autoridad alternativa que el puente original ignoraba; conserva scopes, cuenta, correlation ID y forceRefresh.
- Signout: vuelve a limpiar la cuenta actual al completar el callback, como el original.
- Expiración: vuelve al formato original `yyyy-MM-dd HH:mm:ss` sin offset.

Se conservan el nombre `flutter_msal_plus`, canal, firmas públicas, soporte de configuración sin tenant, documentación, CI y protección de pruebas. También se mantienen comprobaciones de entradas malformadas, callbacks controlados, conversión segura para el códec y eliminación de logs/detalles sensibles. Las diferencias residuales son validación temprana de entradas inválidas, excepciones de inicialización fallida, códigos sanitizados/cancelación explícita y representación segura de claims/nulls. Ninguna modifica los parámetros válidos de inicialización de OmniTool. La API legacy continúa como adaptador; OmniTool utiliza la API estructurada.

## Prueba diferencial y resultados

`RunnerTests.swift` contiene una referencia del constructor original extraída de Git, con su análisis de autoridad y defaults, compilada contra el mismo SDK que el puente actual. Compara client ID, redirect, autoridad, opción existente de validación, autoridades conocidas, grupo de caché, capacidades, lifetime, multicloud y buffer de expiración; después construye ambos clientes reales. Otra prueba pasa los parámetros al handler Flutter real y verifica el éxito y el redirect nativo.

El harness temporal usa el bundle ID y los tres esquemas de OmniTool. Restaura automáticamente el proyecto y el Info.plist del ejemplo al terminar. No modifica el checkout de OmniTool ni llama a autenticación interactiva.

- **68 pruebas Flutter: correctas.** Las respuestas de token son mocks; ejercitan serialización/parsing reales.
- **16 pruebas nativas iOS: correctas.** Inicialización/configuración usan MSAL real, no un cliente mock. Los parámetros silenciosos emplean una cuenta sintética sin credenciales.
- Formato Dart y `flutter analyze`: correctos.
- Evidencia final: `/tmp/msal-restored-native-final-20261008.xcresult` y `/tmp/msal-restored-native-final-20261008.log`.
- No se ha cambiado el SDK, el mínimo iOS, ni los valores de Microsoft; no se ha hecho commit, push, tag o publicación. Los fixtures y este informe siguen excluidos del paquete publicado.

## Riesgos pendientes

La inicialización equivalente no prueba login, consentimiento, acceso a la API, renovación, persistencia de caché ni broker en un dispositivo firmado. El simulador no reproduce la firma/entitlements/caché existentes de OmniTool. Los locks disponibles no permiten certificar la versión del binario publicado. Las diferencias entre SDK 2.0.0 y versiones posteriores requieren aceptación real; no se ha intentado resolverlas cambiando dependencias.

Próxima validación: usar la aplicación real sin cambiar su inicialización ni esquemas, verificar login empresarial, adquisición silenciosa, reinicio, renovación y logout. No registrar ni persistir tokens en informes. **El diagnóstico anterior de incompatibilidad de producción queda retirado; el fallo demostrado era de la configuración incompleta de la prueba.**
