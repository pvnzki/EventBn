import React, { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Plus, Trash2, Grid3x3 } from "lucide-react";

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
  const [seatMap, setSeatMap] = useState<Seat[] | null>(null);

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
    setSeatMap(seatArr);
    onGenerate(seatArr);
  };

  // Add a new row
  const addRow = () => {
    if (numRows < alphabet.length) {
      setNumRows(numRows + 1);
    }
  };

  // Remove a row
  const removeRow = () => {
    if (numRows > 1) {
      setNumRows(numRows - 1);
      // Remove the row ticket type assignment
      const newRowTypes = { ...rowTicketTypes };
      delete newRowTypes[numRows - 1];
      setRowTicketTypes(newRowTypes);
    }
  };

  const getTotalSeats = () => {
    return numRows * seatsPerRow;
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center text-lg">
          <Grid3x3 className="h-5 w-5 mr-2" />
          Seating Arrangement
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {ticketTypes.length === 0 && (
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-3 text-sm text-yellow-800">
            Please add ticket types first before configuring seat map
          </div>
        )}

        <div className="grid grid-cols-2 gap-4">
          <div>
            <Label htmlFor="numRows">Number of Rows</Label>
            <div className="flex gap-2 mt-1">
              <Input
                id="numRows"
                type="number"
                min={1}
                max={alphabet.length}
                value={numRows}
                onChange={(e) => setNumRows(Number(e.target.value))}
                className="flex-1"
              />
              <Button
                type="button"
                variant="outline"
                size="icon"
                onClick={addRow}
                disabled={numRows >= alphabet.length}
              >
                <Plus className="h-4 w-4" />
              </Button>
              <Button
                type="button"
                variant="outline"
                size="icon"
                onClick={removeRow}
                disabled={numRows <= 1}
              >
                <Trash2 className="h-4 w-4" />
              </Button>
            </div>
            <p className="text-xs text-gray-500 mt-1">
              Max {alphabet.length} rows (A-Z)
            </p>
          </div>

          <div>
            <Label htmlFor="seatsPerRow">Seats per Row</Label>
            <Input
              id="seatsPerRow"
              type="number"
              min={1}
              value={seatsPerRow}
              onChange={(e) => setSeatsPerRow(Number(e.target.value))}
              className="mt-1"
            />
            <p className="text-xs text-gray-500 mt-1">
              Total seats: {getTotalSeats()}
            </p>
          </div>
        </div>

        {seatMap && (
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
            <div className="flex justify-between items-center text-sm">
              <span className="text-blue-900 font-medium">
                Current Seat Map:
              </span>
              <div className="flex gap-4">
                <Badge variant="secondary">{seatMap.length} total seats</Badge>
                <Badge variant="default">{seatMap.length} available</Badge>
              </div>
            </div>
          </div>
        )}

        {ticketTypes.length > 0 && (
          <div>
            <Label className="mb-2 block">Assign Ticket Type to Each Row</Label>
            <div className="space-y-2 max-h-64 overflow-y-auto">
              {[...Array(numRows)].map((_, r: number) => (
                <div
                  key={r}
                  className="flex items-center gap-3 p-2 bg-gray-50 rounded-lg"
                >
                  <span className="w-8 h-8 flex items-center justify-center bg-blue-100 text-blue-900 font-bold rounded">
                    {alphabet[r]}
                  </span>
                  <Select
                    value={rowTicketTypes[r] || ""}
                    onValueChange={(value) =>
                      setRowTicketTypes((prev) => ({ ...prev, [r]: value }))
                    }
                  >
                    <SelectTrigger className="flex-1">
                      <SelectValue placeholder="Select ticket type" />
                    </SelectTrigger>
                    <SelectContent>
                      {ticketTypes.map((type: TicketType) => (
                        <SelectItem key={type.id} value={type.id}>
                          {type.name} - ${type.price} (max {type.quantity})
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              ))}
            </div>
          </div>
        )}

        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-3 text-sm text-red-800">
            {error}
          </div>
        )}

        <Button
          type="button"
          onClick={handleGenerate}
          disabled={ticketTypes.length === 0}
          className="w-full"
        >
          <Grid3x3 className="h-4 w-4 mr-2" />
          {seatMap ? "Update Seat Map" : "Generate Seat Map"}
        </Button>

        {/* Colorful Seat Map Visualization */}
        {seatMap && seatMap.length > 0 && (
          <div className="space-y-4 border-t pt-4">
            <h4 className="text-sm font-semibold text-gray-900">
              Seat Map Preview
            </h4>

            {/* Color Legend */}
            <div className="space-y-2">
              <div className="text-xs font-semibold text-gray-700">
                Ticket Categories:
              </div>
              <div className="flex flex-wrap gap-3 text-xs">
                {(() => {
                  // Group seats by ticket type and price
                  const categoryMap = new Map<
                    string,
                    {
                      price: number;
                      count: number;
                      available: number;
                      color: string;
                    }
                  >();

                  const colors = [
                    { bg: "#3b82f6", border: "#1e40af" }, // blue
                    { bg: "#8b5cf6", border: "#6d28d9" }, // purple
                    { bg: "#ec4899", border: "#be185d" }, // pink
                    { bg: "#f59e0b", border: "#d97706" }, // amber
                    { bg: "#14b8a6", border: "#0f766e" }, // teal
                  ];

                  seatMap.forEach((seat) => {
                    const key = `${seat.ticketType}-${seat.price}`;
                    if (!categoryMap.has(key)) {
                      const colorIndex = categoryMap.size % colors.length;
                      categoryMap.set(key, {
                        price: seat.price,
                        count: 0,
                        available: 0,
                        color: colors[colorIndex].bg,
                      });
                    }
                    const data = categoryMap.get(key)!;
                    data.count++;
                    if (seat.available) {
                      data.available++;
                    }
                  });

                  return Array.from(categoryMap.entries()).map(
                    ([key, data], index) => {
                      const ticketTypeId = key.split("-")[0];
                      const ticketType = ticketTypes.find(
                        (tt) => tt.id === ticketTypeId
                      );
                      const categoryName =
                        ticketType?.name || `Category ${index + 1}`;

                      return (
                        <div key={key} className="flex items-center gap-1">
                          <div
                            className="w-5 h-5 rounded border-2"
                            style={{
                              backgroundColor: data.color,
                              borderColor: data.color,
                              opacity: 0.9,
                            }}
                          />
                          <span className="font-medium">
                            {categoryName} - ${data.price} ({data.available}/
                            {data.count})
                          </span>
                        </div>
                      );
                    }
                  );
                })()}
              </div>
            </div>

            {/* Seat Grid */}
            <div className="space-y-3 max-h-96 overflow-y-auto">
              {(() => {
                // Group seats by row
                const rowMap = new Map<string, Seat[]>();
                seatMap.forEach((seat) => {
                  const row = seat.label.charAt(0);
                  if (!rowMap.has(row)) {
                    rowMap.set(row, []);
                  }
                  rowMap.get(row)!.push(seat);
                });

                const sortedRows = Array.from(rowMap.keys()).sort();

                // Assign colors to categories
                const colors = [
                  { bg: "#3b82f6", border: "#1e40af" },
                  { bg: "#8b5cf6", border: "#6d28d9" },
                  { bg: "#ec4899", border: "#be185d" },
                  { bg: "#f59e0b", border: "#d97706" },
                  { bg: "#14b8a6", border: "#0f766e" },
                ];

                const categoryColorMap = new Map<string, (typeof colors)[0]>();
                seatMap.forEach((seat) => {
                  const key = `${seat.ticketType}-${seat.price}`;
                  if (!categoryColorMap.has(key)) {
                    const colorIndex = categoryColorMap.size % colors.length;
                    categoryColorMap.set(key, colors[colorIndex]);
                  }
                });

                return sortedRows.map((row) => {
                  const rowSeats = rowMap
                    .get(row)!
                    .sort((a, b) => a.label.localeCompare(b.label));

                  return (
                    <div key={row} className="flex items-center gap-3">
                      <div className="w-8 text-sm font-semibold text-gray-700 flex-shrink-0">
                        {row}
                      </div>
                      <div className="flex gap-2 flex-wrap">
                        {rowSeats.map((seat) => {
                          const isAvailable = seat.available === true;

                          const categoryKey = `${seat.ticketType}-${seat.price}`;
                          const categoryColor =
                            categoryColorMap.get(categoryKey);

                          let bgColor, textColor, borderColor;
                          if (isAvailable && categoryColor) {
                            bgColor = categoryColor.bg;
                            textColor = "#ffffff";
                            borderColor = categoryColor.border;
                          } else {
                            bgColor = "#ffffff";
                            textColor = "#374151";
                            borderColor = "#d1d5db";
                          }

                          return (
                            <div
                              key={seat.id}
                              className="w-12 h-12 flex items-center justify-center text-xs font-semibold border-2 rounded transition-all cursor-default"
                              style={{
                                backgroundColor: bgColor,
                                color: textColor,
                                borderColor: borderColor,
                              }}
                              title={`${seat.label} - Available - $${seat.price}`}
                            >
                              {seat.label}
                            </div>
                          );
                        })}
                      </div>
                    </div>
                  );
                });
              })()}
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
};

export default SeatingArrangementSection;
