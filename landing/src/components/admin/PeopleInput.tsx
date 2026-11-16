"use client";

import { useEffect, useId, useRef, useState } from "react";
import { searchPeople, type Person } from "@/lib/admin";

export type Chip = { name: string; isNew: boolean };

const key = (s: string) => s.replace(/\s+/g, " ").trim().toLowerCase();

/**
 * Multi-person picker backed by the People table.
 * - Suggestions from the DB as you type (↑/↓ + Enter, or click).
 * - Comma or Enter commits what's typed; pasting "A, B, C" adds all three.
 * - A name that matches an existing person (any case) snaps to its stored
 *   spelling; anything else becomes a "new" chip, created on save.
 */
export default function PeopleInput({
  label,
  hint,
  value,
  onChange,
}: {
  label: string;
  hint?: string;
  value: Chip[];
  onChange: (chips: Chip[]) => void;
}) {
  const [text, setText] = useState("");
  const [suggestions, setSuggestions] = useState<Person[]>([]);
  const [highlight, setHighlight] = useState(0);
  const [open, setOpen] = useState(false);
  const listId = useId();
  const inputRef = useRef<HTMLInputElement>(null);
  const reqId = useRef(0);

  const taken = new Set(value.map((c) => key(c.name)));

  // Debounced suggestions; ignores responses that arrive out of order.
  useEffect(() => {
    const q = text.trim();
    if (!q) {
      setSuggestions([]);
      return;
    }
    const id = ++reqId.current;
    const t = setTimeout(async () => {
      try {
        const found = await searchPeople(q);
        if (id === reqId.current) {
          setSuggestions(found);
          setHighlight(0);
        }
      } catch {
        // Suggestions are a convenience; typing still works without them.
      }
    }, 150);
    return () => clearTimeout(t);
  }, [text]);

  const visible = suggestions.filter((p) => !taken.has(key(p.name)));
  const typed = text.replace(/\s+/g, " ").trim();
  const exact = visible.find((p) => key(p.name) === key(typed));
  const canAddNew = typed.length > 0 && !exact && !taken.has(key(typed));
  // Options: suggestions, then "+ Add <typed>" when it's not an existing name.
  const optionCount = visible.length + (canAddNew ? 1 : 0);

  async function commit(names: string[]) {
    const next = [...value];
    const seen = new Set(next.map((c) => key(c.name)));
    for (const raw of names) {
      const name = raw.replace(/\s+/g, " ").trim();
      if (!name || seen.has(key(name))) continue;
      // Snap to the stored spelling if this name already exists.
      let match = suggestions.find((p) => key(p.name) === key(name));
      if (!match) {
        try {
          match = (await searchPeople(name)).find((p) => key(p.name) === key(name));
        } catch {}
      }
      next.push(match ? { name: match.name, isNew: false } : { name, isNew: true });
      seen.add(key(name));
    }
    onChange(next);
    setText("");
    setSuggestions([]);
  }

  function pick(index: number) {
    if (index < visible.length) {
      onChange([...value, { name: visible[index].name, isNew: false }]);
      setText("");
      setSuggestions([]);
    } else if (canAddNew) {
      commit([typed]);
    }
    inputRef.current?.focus();
  }

  function onKeyDown(e: React.KeyboardEvent<HTMLInputElement>) {
    if (e.key === "ArrowDown" && optionCount) {
      e.preventDefault();
      setOpen(true);
      setHighlight((h) => (h + 1) % optionCount);
    } else if (e.key === "ArrowUp" && optionCount) {
      e.preventDefault();
      setHighlight((h) => (h - 1 + optionCount) % optionCount);
    } else if (e.key === "Enter") {
      if (!typed) return; // let Enter submit the form when the box is empty
      e.preventDefault();
      if (open && optionCount) pick(highlight);
      else commit([typed]);
    } else if (e.key === ",") {
      e.preventDefault();
      if (typed) commit([typed]);
    } else if (e.key === "Backspace" && !text && value.length) {
      onChange(value.slice(0, -1));
    } else if (e.key === "Escape") {
      setOpen(false);
    }
  }

  function onTextChange(v: string) {
    if (v.includes(",")) {
      // Pasted or typed a list: commit everything before the last comma.
      const parts = v.split(",");
      const rest = parts.pop() ?? "";
      commit(parts);
      setText(rest.trimStart());
    } else {
      setText(v);
    }
    setOpen(true);
  }

  return (
    <div className="block relative">
      <span className="text-sm font-medium">{label}</span>
      {hint ? <span className="block text-xs text-outline">{hint}</span> : null}
      <div
        className="mt-1 w-full rounded-lg hairline px-2 py-1.5 bg-white flex flex-wrap items-center gap-1.5 min-h-[44px] cursor-text"
        onClick={() => inputRef.current?.focus()}
      >
        {value.map((c, i) => (
          <span
            key={c.name}
            className={`inline-flex items-center gap-1 rounded-full pl-3 pr-1 py-1 text-sm ${
              c.isNew
                ? "bg-amber-50 text-amber-900 ring-1 ring-amber-300"
                : "bg-[#E8F3EE] text-[#054A29]"
            }`}
            title={c.isNew ? "New — will be added to the People list when you save" : undefined}
          >
            {c.name}
            {c.isNew ? (
              <span className="text-[10px] font-bold uppercase tracking-wide opacity-70">new</span>
            ) : null}
            <button
              type="button"
              aria-label={`Remove ${c.name}`}
              onClick={(e) => {
                e.stopPropagation();
                onChange(value.filter((_, j) => j !== i));
              }}
              className="w-5 h-5 rounded-full hover:bg-black/10 leading-none"
            >
              ×
            </button>
          </span>
        ))}
        <input
          ref={inputRef}
          value={text}
          onChange={(e) => onTextChange(e.target.value)}
          onKeyDown={onKeyDown}
          onFocus={() => setOpen(true)}
          onBlur={() => setTimeout(() => setOpen(false), 150)}
          placeholder={value.length ? "" : "Start typing a name…"}
          className="flex-1 min-w-[140px] outline-none py-1 px-1 bg-transparent"
          role="combobox"
          aria-expanded={open && optionCount > 0}
          aria-controls={listId}
          aria-autocomplete="list"
        />
      </div>

      {open && optionCount > 0 ? (
        <ul
          id={listId}
          role="listbox"
          className="absolute z-20 mt-1 w-full rounded-lg bg-white hairline shadow-lg py-1 max-h-64 overflow-auto"
        >
          {visible.map((p, i) => (
            <li
              key={p.id}
              role="option"
              aria-selected={highlight === i}
              onMouseDown={(e) => {
                e.preventDefault();
                pick(i);
              }}
              onMouseEnter={() => setHighlight(i)}
              className={`px-3 py-2 text-sm cursor-pointer ${highlight === i ? "bg-surface-container" : ""}`}
            >
              {p.name}
            </li>
          ))}
          {canAddNew ? (
            <li
              role="option"
              aria-selected={highlight === visible.length}
              onMouseDown={(e) => {
                e.preventDefault();
                pick(visible.length);
              }}
              onMouseEnter={() => setHighlight(visible.length)}
              className={`px-3 py-2 text-sm cursor-pointer border-t border-outline-variant/40 ${
                highlight === visible.length ? "bg-surface-container" : ""
              }`}
            >
              + Add <strong>&ldquo;{typed}&rdquo;</strong> as new
            </li>
          ) : null}
        </ul>
      ) : null}
    </div>
  );
}
