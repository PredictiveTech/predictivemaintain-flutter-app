/// Política de reintentos de Riverpod 3: ninguno. Un error de carga se muestra
/// y el usuario decide cuándo reintentar con el botón "Reintentar".
Duration? noRetry(int retryCount, Object error) => null;
