import React, { useState } from "react";

const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split("");

interface TicketType {
  id: string;
  name: string;
  price: number;
  quantity: number;
}

interface Seat {
  id: number;
  label: string;
  price: number;
  available: boolean;
  ticketType: string;
}

interface SeatingArrangementSectionProps {
  ticketTypes: TicketType[];
  onGenerate: (seatMapArray: Seat[]) => void;
}

const SeatingArrangementSection: React.FC<SeatingArrangementSectionProps> = ({
  ticketTypes,
  onGenerate,
}) => {
  const [numRows, setNumRows] = useState<number>(1);
  const [seatsPerRow, setSeatsPerRow] = useState<number>(1);
  const [rowTicketTypes, setRowTicketTypes] = useState<Record<number, string>>(
    {}
  );
  const [error, setError] = useState<string>("");

  // Count seats per ticket type
  const getTicketTypeCounts = (): Record<string, number> => {
    const counts: Record<string, number> = {};
    for (let r = 0; r < numRows; r++) {
      const type: string = rowTicketTypes[r] || ticketTypes[0]?.id;
      counts[type] = (counts[type] || 0) + seatsPerRow;
    }
    return counts;
  };

  // Validate seat counts
  const validate = (): string | null => {
    const counts = getTicketTypeCounts();
    for (const type of ticketTypes) {
      if ((counts[type.id] || 0) > type.quantity) {
        return `Too many seats for ticket type ${type.name}`;
      }
    }
    return null;
  };

  // Generate seat map array
  const handleGenerate = (): void => {
    const err = validate();
    if (err) {
      setError(err);
      return;
    }
    setError("");
    const seatArr: Seat[] = [];
    let seatId = 1;
    for (let r = 0; r < numRows; r++) {
      const rowLabel = alphabet[r];
      const ticketType = rowTicketTypes[r] || ticketTypes[0]?.id;
      const price =
        ticketTypes.find((t: TicketType) => t.id === ticketType)?.price || 0;
      for (let s = 1; s <= seatsPerRow; s++) {
        seatArr.push({
          id: seatId++,
          label: `${rowLabel}${s}`,
          price,
          available: true,
          ticketType,
        });
      }
    }
    onGenerate(seatArr);
  };

  return (
    <div className="space-y-4 border rounded-lg p-4 mt-4">
      <h4 className="font-medium">Seating Arrangement</h4>
      <div className="flex gap-4">
        <div>
          <label className="block text-sm font-medium">Rows</label>
          <input
            type="number"
            min={1}
            max={alphabet.length}
            value={numRows}
            onChange={(e) => setNumRows(Number(e.target.value))}
            className="border rounded px-2 py-1 w-20"
          />
        </div>
        <div>
          <label className="block text-sm font-medium">Seats per Row</label>
          <input
            type="number"
            min={1}
            value={seatsPerRow}
            onChange={(e) => setSeatsPerRow(Number(e.target.value))}
            className="border rounded px-2 py-1 w-24"
          />
        </div>
      </div>
      <div>
        <label className="block text-sm font-medium mb-2">
          Assign Ticket Type to Each Row
        </label>
        {[...Array(numRows)].map((_, r: number) => (
          <div key={r} className="flex items-center gap-2 mb-1">
            <span className="w-6 inline-block">{alphabet[r]}</span>
            <select
              value={rowTicketTypes[r] || ""}
              onChange={(e) =>
                setRowTicketTypes((prev) => ({ ...prev, [r]: e.target.value }))
              }
              className="border rounded px-2 py-1"
            >
              <option value="" disabled>
                Select ticket type
              </option>
              {ticketTypes.map((type: TicketType) => (
                <option key={type.id} value={type.id}>
                  {type.name} (max {type.quantity})
                </option>
              ))}
            </select>
          </div>
        ))}
      </div>
      {error && <div className="text-red-600 text-sm">{error}</div>}
      <button
        type="button"
        className="mt-2 px-4 py-2 bg-blue-600 text-white rounded"
        onClick={handleGenerate}
      >
        Generate Seat Map
      </button>
    </div>
  );
};

export default SeatingArrangementSection;
