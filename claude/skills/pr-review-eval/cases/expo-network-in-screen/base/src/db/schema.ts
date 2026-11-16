import { integer, sqliteTable, text } from 'drizzle-orm/sqlite-core';

export const cards = sqliteTable('cards', {
  id: text('id').primaryKey(),
  name: text('name').notNull(),
  rarity: integer('rarity').notNull(),
});

export const producers = sqliteTable('producers', {
  id: text('id').primaryKey(),
  cardId: text('card_id').notNull(),
  name: text('name').notNull(),
  village: text('village').notNull(),
});

export const tastings = sqliteTable('tastings', {
  id: text('id').primaryKey(),
  cardId: text('card_id').notNull(),
  tastedOn: text('tasted_on').notNull(),
});
