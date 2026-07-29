import "@testing-library/jest-dom";
import { vi } from "vitest";

// jsdom no implementa fetch: el efecto de App.tsx lo llama al montar,
// así que sin este stub cualquier test que renderice App lanza
// "fetch is not defined" antes de llegar a las aserciones.
globalThis.fetch = vi.fn(
  () => new Promise(() => {}),
) as unknown as typeof fetch;
