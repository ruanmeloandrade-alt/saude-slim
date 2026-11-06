type RecentRow = {
  id: string;
  lastMessageAt?: string | null;
  lastInboundAt?: string | null;
  createdAt?: string | null;
};

function recentTimestamp(row: RecentRow): number {
  return Math.max(
    0,
    ...[row.lastMessageAt, row.lastInboundAt, row.createdAt].map((value) => {
      const timestamp = value ? Date.parse(value) : NaN;
      return Number.isFinite(timestamp) ? timestamp : 0;
    }),
  );
}

/** New activity first; missing dates never disrupt the rest of the list. */
export function recentFirst(a: RecentRow, b: RecentRow): number {
  return recentTimestamp(b) - recentTimestamp(a) || a.id.localeCompare(b.id);
}
