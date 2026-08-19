import { useState } from "react";
import { useNavigate } from "react-router-dom";
import UploadDropzone from "../components/UploadDropzone.jsx";
import ColumnMapper, { applyMapping, autoGuess } from "../components/ColumnMapper.jsx";
import UploadPreviewTable from "../components/UploadPreviewTable.jsx";
import { api } from "../api/client.js";

// Phases: "idle" -> "parsing" -> ("mapper" | "preview") -> "committing" -> "done"
export default function Upload() {
  const navigate = useNavigate();
  const [phase, setPhase] = useState("idle");
  const [filename, setFilename] = useState("");
  const [broker, setBroker] = useState("");
  const [headers, setHeaders] = useState([]);
  const [rawRows, setRawRows] = useState([]);
  const [mapping, setMapping] = useState({});
  const [rows, setRows] = useState([]);
  const [err, setErr] = useState(null);

  const handleFile = async (file) => {
    setFilename(file.name);
    setErr(null);
    setPhase("parsing");
    try {
      const fd = new FormData();
      fd.append("file", file);
      const res = await api.uploadPreview(fd);

      setBroker(res.broker);
      setHeaders(res.headers || []);

      if (res.broker === "generic") {
        setRawRows(res.rows || []);
        setMapping(autoGuess(res.headers || []));
        setPhase("mapper");
      } else {
        // Broker parser produced rows directly.
        setRows(res.rows || []);
        setPhase("preview");
      }
    } catch (e) {
      setErr(String(e.message || e));
      setPhase("idle");
    }
  };

  const handleApplyMapping = () => {
    // Validate required fields.
    const required = ["date", "stock", "buyPrice", "lots"];
    const missing = required.filter((k) => !mapping[k]);
    if (missing.length) {
      setErr(`Missing required mappings: ${missing.join(", ")}`);
      return;
    }
    setErr(null);
    setRows(applyMapping(rawRows, mapping, headers));
    setPhase("preview");
  };

  const handleCommit = async () => {
    setPhase("committing");
    try {
      await api.uploadCommit({ broker, filename, rows });
      setPhase("done");
      navigate("/journal");
    } catch (e) {
      setErr(String(e.message || e));
      setPhase("preview");
    }
  };

  const reset = () => {
    setPhase("idle");
    setFilename("");
    setBroker("");
    setHeaders([]);
    setRawRows([]);
    setMapping({});
    setRows([]);
    setErr(null);
  };

  return (
    <div className="space-y-4 max-w-5xl">
      <div className="flex items-baseline justify-between">
        <h2 className="text-lg font-medium">Upload trades</h2>
        {phase !== "idle" ? (
          <button onClick={reset} className="text-sm text-neutral-400 hover:text-white">
            Start over
          </button>
        ) : null}
      </div>

      {err ? <div className="text-loss text-sm">{err}</div> : null}

      {phase === "idle" || phase === "parsing" ? (
        <UploadDropzone onFile={handleFile} disabled={phase === "parsing"} />
      ) : null}

      {phase === "mapper" ? (
        <ColumnMapper
          headers={headers}
          mapping={mapping}
          onChange={setMapping}
          onApply={handleApplyMapping}
          onCancel={reset}
        />
      ) : null}

      {phase === "preview" || phase === "committing" ? (
        <>
          <div className="text-sm text-neutral-400">
            <span className="text-neutral-500">Detected:</span> {broker}
            <span className="text-neutral-500 ml-3">File:</span> {filename}
            <span className="text-neutral-500 ml-3">Rows:</span> {rows.length}
          </div>
          <UploadPreviewTable
            rows={rows}
            setRows={setRows}
            onCommit={handleCommit}
            onCancel={reset}
          />
        </>
      ) : null}

      {phase === "done" ? (
        <div className="text-gain text-sm">Committed. Redirecting…</div>
      ) : null}
    </div>
  );
}
