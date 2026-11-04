import { z } from "zod";

export const scanProfileSchema = z.object({
  id: z.string().uuid(),
  name: z.string().trim().min(1).max(80),
  rules: z.string().trim().min(1).max(12000),
  reviewStage: z.string().uuid().nullable(),
  sourceStages: z.array(z.string().uuid()).max(100),
  days: z.array(z.number().int().min(0).max(6)).max(7),
  time: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/),
  scheduled: z.boolean(),
}).refine((profile) => !profile.scheduled || profile.days.length > 0, "Escolha os dias da varredura.");

export type ScanProfile = z.infer<typeof scanProfileSchema>;
export const scanTimeZone = "America/Sao_Paulo";

export function scheduledSlot(profile: ScanProfile, now: Date): string | null {
  if (!profile.scheduled) return null;
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone: scanTimeZone, weekday: "short", year: "numeric", month: "2-digit",
    day: "2-digit", hour: "2-digit", minute: "2-digit", hourCycle: "h23",
  }).formatToParts(now);
  const part = (type: Intl.DateTimeFormatPartTypes) => parts.find((value) => value.type === type)?.value ?? "";
  const day = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].indexOf(part("weekday"));
  const time = `${part("hour")}:${part("minute")}`;
  if (!profile.days.includes(day) || time < profile.time) return null;
  return `${part("year")}-${part("month")}-${part("day")}`;
}
