import { useEffect, useState } from "react";

interface HealthResponse {
  status: string;
  app_env: string;
  timestamp: string;
}

const API_BASE_URL =
  (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? "http://localhost:8000/api/v1";

export default function App() {
  const [health, setHealth] = useState<HealthResponse | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const controller = new AbortController();
    fetch(`${API_BASE_URL}/health`, { signal: controller.signal })
      .then((res) => {
        if (!res.ok) throw new Error(`La API respondió ${res.status}`);
        return res.json() as Promise<HealthResponse>;
      })
      .then(setHealth)
      .catch((err: Error) => {
        if (err.name !== "AbortError") setError(err.message);
      });
    return () => controller.abort();
  }, []);

  return (
    <main className="min-h-screen bg-ink text-vellum px-6 py-10">
      <h1 className="font-display text-4xl mb-2">INGENIUM TRACKER</h1>
      <p className="font-reading text-vellum-dim max-w-prose mb-6">
        Cartografía filológica del concepto de <em>ingenium</em> en la literatura filosófica y
        técnica de acceso abierto. Esta vista se completará en la FASE 5 con el mapa, la línea de
        tiempo y el cajón de marginalia.
      </p>
      <div className="font-mono text-sm border border-rule rounded p-4 bg-ink-2">
        {error && (
          <p role="alert" className="text-vermilion">
            No se pudo contactar la API en {API_BASE_URL}: {error}
          </p>
        )}
        {!error && !health && <p aria-live="polite">Consultando estado de la API…</p>}
        {health && (
          <dl aria-live="polite" className="grid grid-cols-[auto_1fr] gap-x-4 gap-y-1">
            <dt>status</dt>
            <dd>{health.status}</dd>
            <dt>app_env</dt>
            <dd>{health.app_env}</dd>
            <dt>timestamp</dt>
            <dd>{health.timestamp}</dd>
          </dl>
        )}
      </div>
    </main>
  );
}
