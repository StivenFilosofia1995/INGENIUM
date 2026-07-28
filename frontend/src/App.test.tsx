import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import App from "../App";

describe("App", () => {
  it("muestra el título INGENIUM TRACKER", () => {
    render(<App />);
    expect(screen.getByText("INGENIUM TRACKER")).toBeInTheDocument();
  });

  it("muestra un estado de carga inicial accesible", () => {
    render(<App />);
    expect(screen.getByText(/Consultando estado de la API/)).toBeInTheDocument();
  });
});
