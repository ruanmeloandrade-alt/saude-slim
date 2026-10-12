import { useEffect } from "react";
import { useServerFn } from "@tanstack/react-start";
import { supabase } from "@/integrations/supabase/client";
import { touchSession } from "@/lib/sessions.functions";

const KEY = "mkton_device_key";

export function getDeviceKey(): string {
  if (typeof window === "undefined") return "";
  let k = localStorage.getItem(KEY);
  if (!k) {
    k = (crypto.randomUUID?.() ?? `${Date.now()}-${Math.random().toString(36).slice(2)}`).replace(/-/g, "").slice(0, 32);
    localStorage.setItem(KEY, k);
  }
  return k;
}

export function parseUA(ua: string) {
  const browser = /Edg\//.test(ua) ? "Edge"
    : /OPR\//.test(ua) ? "Opera"
    : /Chrome\//.test(ua) ? "Chrome"
    : /Firefox\//.test(ua) ? "Firefox"
    : /Safari\//.test(ua) ? "Safari"
    : "Navegador";
  const os = /Windows/.test(ua) ? "Windows"
    : /Android/.test(ua) ? "Android"
    : /iPhone|iPad|iPod/.test(ua) ? "iOS"
    : /Mac OS X/.test(ua) ? "macOS"
    : /Linux/.test(ua) ? "Linux"
    : "Sistema";
  const device_type = /iPad|Tablet/.test(ua) ? "tablet"
    : /Mobi|Android|iPhone/.test(ua) ? "mobile"
    : "desktop";
  return { browser, os, device_type };
}

/** Registra e mantém viva a sessão do dispositivo atual (heartbeat de 60s). */
export function useSessionHeartbeat() {
  const touch = useServerFn(touchSession);

  useEffect(() => {
    let alive = true;
    let timer: ReturnType<typeof setInterval> | null = null;

    const ping = async () => {
      if (!alive || typeof document === "undefined" || document.visibilityState === "hidden") return;
      const { data } = await supabase.auth.getSession();
      if (!data.session) return;
      const ua = navigator.userAgent;
      try {
        const r: any = await touch({
          data: {
            device_key: getDeviceKey(),
            login_at: data.session.user.last_sign_in_at ?? undefined,
            current_path: window.location.pathname,
            ...parseUA(ua),
          },
        });
        if (r?.revoked) {
          await supabase.auth.signOut();
          window.location.href = "/auth";
        }
      } catch {
        /* silencioso */
      }
    };

    void ping();
    timer = setInterval(ping, 60_000);
    document.addEventListener("visibilitychange", ping);
    return () => {
      alive = false;
      if (timer) clearInterval(timer);
      document.removeEventListener("visibilitychange", ping);
    };
  }, [touch]);
}
