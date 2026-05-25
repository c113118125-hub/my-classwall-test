"use client";

import { useCallback, useEffect, useState } from "react";

import { supabase } from "@/lib/supabase";
import type { Review } from "@/types/database";

/**
 * 載入單一 restaurant 的評論 + Realtime 訂閱
 *
 * 用法：在 RestaurantCard 展開時 mount 這個 hook，
 * 收起時 unmount 即自動取消訂閱（節省連線數）。
 *
 * 載入順序：時間升冪（舊 → 新，像聊天訊息）
 */
export function useAnswers(questionId: string) {
  const [answers, setAnswers] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      const { data, error: fetchError } = await supabase
        .from("reviews")
        .select("*")
        .eq("restaurant_id", questionId)
        .order("created_at", { ascending: true });

      if (cancelled) return;
      if (fetchError) {
        setError(fetchError.message);
      } else {
        setAnswers(data ?? []);
      }
      setLoading(false);
    }

    load();

    // Realtime：只訂閱該餐廳的 INSERT
    const channel = supabase
      .channel(`answers-${questionId}`)
      .on(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "reviews",
          filter: `restaurant_id=eq.${questionId}`,
        },
        (payload) => {
          const next = payload.new as Review;
          setAnswers((prev) =>
            prev.some((a) => a.id === next.id) ? prev : [...prev, next]
          );
        }
      )
      .subscribe();

    return () => {
      cancelled = true;
      supabase.removeChannel(channel);
    };
  }, [questionId]);

  const addAnswer = useCallback(
    async (content: string) => {
      const trimmed = content.trim();
      if (!trimmed) return { error: "評論不能為空" };

      const { error: insertError } = await supabase
        .from("reviews")
        .insert({ restaurant_id: questionId, content: trimmed });

      if (insertError) return { error: insertError.message };
      return { error: null };
    },
    [questionId]
  );

  return { answers, loading, error, addAnswer };
}
