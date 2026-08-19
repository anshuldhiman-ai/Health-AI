import { useState } from "react";

// Drag-and-drop OR click-to-pick. Single file. Surfaces file errors inline.
export default function UploadDropzone({ onFile, disabled }) {
  const [drag, setDrag] = useState(false);
  const [err, setErr] = useState(null);

  const accept = (f) => {
    if (!f) return;
    const name = f.name.toLowerCase();
    if (!(name.endsWith(".csv") || name.endsWith(".xlsx") || name.endsWith(".xls") || name.endsWith(".pdf"))) {
      setErr("Only .csv, .xlsx, or .pdf are supported.");
      return;
    }
    setErr(null);
    onFile(f);
  };

  return (
    <div>
      <label
        onDragOver={(e) => {
          e.preventDefault();
          if (!disabled) setDrag(true);
        }}
        onDragLeave={() => setDrag(false)}
        onDrop={(e) => {
          e.preventDefault();
          setDrag(false);
          accept(e.dataTransfer.files?.[0]);
        }}
        className={`block border-2 border-dashed rounded-lg p-10 text-center cursor-pointer transition-colors ${
          drag ? "border-white bg-neutral-800" : "border-neutral-700 bg-neutral-900 hover:border-neutral-500"
        } ${disabled ? "opacity-50 cursor-not-allowed" : ""}`}
      >
        <input
          type="file"
          accept=".csv,.xlsx,.xls,.pdf"
          className="hidden"
          disabled={disabled}
          onChange={(e) => accept(e.target.files?.[0])}
        />
        <div className="text-neutral-300">
          {disabled ? "Parsing…" : "Drop a broker file here or click to browse"}
        </div>
        <div className="mt-1 text-xs text-neutral-500">CSV, XLSX, or PDF</div>
      </label>
      {err ? <div className="mt-2 text-loss text-sm">{err}</div> : null}
    </div>
  );
}
