import { q, one, type Db, pool } from '../db.js';

/** India time: due dates and "overdue" are judged by the shop's calendar day. */
export function todayIST(now = new Date()): string {
  return new Date(now.getTime() + 5.5 * 3600_000).toISOString().slice(0, 10);
}

export function addMonths(isoDate: string, months: number): string {
  const [y, m, d] = isoDate.split('-').map(Number);
  const target = new Date(Date.UTC(y, m - 1 + months, 1));
  const lastDay = new Date(Date.UTC(target.getUTCFullYear(), target.getUTCMonth() + 1, 0)).getUTCDate();
  target.setUTCDate(Math.min(d, lastDay));
  return target.toISOString().slice(0, 10);
}

export function daysBetween(fromIso: string, toIso: string): number {
  return Math.round((Date.parse(toIso + 'T00:00:00Z') - Date.parse(fromIso + 'T00:00:00Z')) / 86400_000);
}

export function buildSchedule(firstEmiDate: string, emiCount: number, emiAmount: number) {
  return Array.from({ length: emiCount }, (_, i) => ({ seq: i + 1, dueDate: addMonths(firstEmiDate, i), amount: emiAmount }));
}

export async function createInstalments(loanId: string, firstEmiDate: string, emiCount: number, emiAmount: number, db: Db) {
  for (const s of buildSchedule(firstEmiDate, emiCount, emiAmount)) {
    await q('insert into instalments(loan_id, seq, due_date, amount) values ($1,$2,$3,$4)', [loanId, s.seq, s.dueDate, s.amount], db);
  }
}

export interface LoanSummary {
  loanId: string;
  status: 'open' | 'closed';
  paidCount: number;
  emiCount: number;
  paidTotal: number;
  balance: number;
  overdueAmount: number;
  overdueCount: number;
  overdueDays: number;
  nextDueDate: string | null;
  nextDueAmount: number | null;
}

export async function loanSummary(deviceId: string, db: Db = pool, today = todayIST()): Promise<LoanSummary | null> {
  const loan = await one<{ id: string; status: 'open' | 'closed'; emi_count: number }>(
    'select id, status, emi_count from loans where device_id = $1', [deviceId], db);
  if (!loan) return null;
  const inst = await q<{ due_date: string; amount: number; paid_amount: number; paid_at: string | null }>(
    'select due_date, amount, paid_amount, paid_at from instalments where loan_id = $1 order by seq', [loan.id], db);
  let paidCount = 0, paidTotal = 0, balance = 0, overdueAmount = 0, overdueCount = 0;
  let oldestOverdue: string | null = null;
  let next: { due_date: string; amount: number } | null = null;
  for (const i of inst) {
    paidTotal += i.paid_amount;
    if (i.paid_at) { paidCount++; continue; }
    const remaining = i.amount - i.paid_amount;
    balance += remaining;
    if (i.due_date < today) {
      overdueAmount += remaining; overdueCount++;
      oldestOverdue ??= i.due_date;
    }
    if (!next) next = { due_date: i.due_date, amount: remaining };
  }
  return {
    loanId: loan.id,
    status: loan.status,
    paidCount,
    emiCount: loan.emi_count,
    paidTotal: round2(paidTotal),
    balance: round2(balance),
    overdueAmount: round2(overdueAmount),
    overdueCount,
    overdueDays: oldestOverdue ? daysBetween(oldestOverdue, today) : 0,
    nextDueDate: next?.due_date ?? null,
    nextDueAmount: next ? round2(next.amount) : null,
  };
}

export const round2 = (n: number) => Math.round(n * 100) / 100;

/**
 * Applies a payment to the oldest unpaid instalments. Returns how much was applied.
 * Closes the loan when everything is paid.
 */
export async function applyPayment(
  loanId: string, amount: number, method: string, ref: string, userId: string | null, db: Db,
): Promise<{ applied: number; closed: boolean }> {
  let left = round2(amount);
  const rows = await q<{ id: string; amount: number; paid_amount: number }>(
    'select id, amount, paid_amount from instalments where loan_id = $1 and paid_at is null order by seq for update', [loanId], db);
  for (const r of rows) {
    if (left <= 0) break;
    const need = round2(r.amount - r.paid_amount);
    const pay = Math.min(need, left);
    left = round2(left - pay);
    const full = round2(r.paid_amount + pay) >= r.amount;
    await q(
      `update instalments set paid_amount = paid_amount + $2, method = $3, ref = $4, recorded_by = $5,
         paid_at = case when $6 then now() else null end where id = $1`,
      [r.id, pay, method, ref, userId, full], db);
  }
  const open = await one<{ n: number }>('select count(*)::int as n from instalments where loan_id = $1 and paid_at is null', [loanId], db);
  const closed = open!.n === 0;
  if (closed) await q("update loans set status = 'closed' where id = $1", [loanId], db);
  return { applied: round2(amount - left), closed };
}
