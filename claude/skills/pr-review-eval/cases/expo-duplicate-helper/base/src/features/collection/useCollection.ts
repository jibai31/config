import { eq } from 'drizzle-orm';
import { useLiveQuery } from 'drizzle-orm/expo-sqlite';

import { db } from '../../db/client';
import { cards, producers } from '../../db/schema';

export function useCollection() {
  const { data } = useLiveQuery(db.select().from(cards).orderBy(cards.name));
  return data ?? [];
}

export function useProducers(cardId: string) {
  const { data } = useLiveQuery(db.select().from(producers).where(eq(producers.cardId, cardId)), [cardId]);
  return data ?? [];
}
