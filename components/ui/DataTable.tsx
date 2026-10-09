import React from 'react';

export interface Column<T> {
  key: string;
  header: string;
  render?: (row: T) => React.ReactNode;
  className?: string;
}

interface DataTableProps<T> {
  columns: Column<T>[];
  data: T[];
  loading?: boolean;
  emptyMessage?: string;
  keyExtractor: (row: T) => string;
  onRowClick?: (row: T) => void;
}

function TableSkeleton({ cols }: { cols: number }) {
  return (
    <>
      {Array.from({ length: 5 }).map((_, i) => (
        <tr key={`skel-${i}`}>
          {Array.from({ length: cols }).map((_, j) => (
            <td key={`skel-${i}-${j}`} className="px-4 py-3">
              <div className="h-4 bg-[#0F2347] rounded animate-pulse" />
            </td>
          ))}
        </tr>
      ))}
    </>
  );
}

export default function DataTable<T>({
  columns,
  data,
  loading = false,
  emptyMessage = 'Aucune donnée pour ces filtres.',
  keyExtractor,
  onRowClick,
}: DataTableProps<T>) {
  return (
    <div className="overflow-x-auto rounded-2xl border border-[rgba(212,175,55,0.15)]">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-[rgba(212,175,55,0.1)] bg-[#08152f]">
            {columns.map(col => (
              <th
                key={col.key}
                className={`px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-[#A0AEC0] ${col.className ?? ''}`}
              >
                {col.header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-[rgba(212,175,55,0.06)]">
          {loading ? (
            <TableSkeleton cols={columns.length} />
          ) : data.length === 0 ? (
            <tr>
              <td colSpan={columns.length} className="px-4 py-12 text-center text-sm text-[#718096]">
                {emptyMessage}
              </td>
            </tr>
          ) : (
            data.map(row => (
              <tr
                key={keyExtractor(row)}
                onClick={onRowClick ? () => onRowClick(row) : undefined}
                className={`bg-[#0F2347]/60 table-row-hover transition-colors ${onRowClick ? 'cursor-pointer' : ''}`}
              >
                {columns.map(col => (
                  <td key={col.key} className={`px-4 py-3 text-[#F7F9FC] ${col.className ?? ''}`}>
                    {col.render ? col.render(row) : (row as Record<string, unknown>)[col.key] as React.ReactNode}
                  </td>
                ))}
              </tr>
            ))
          )}
        </tbody>
      </table>
    </div>
  );
}
