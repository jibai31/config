import { Pressable, Text } from 'react-native';

type Props = { name: string; rarity: number; collected: boolean; onPress: () => void };

function rarityLabel(rarity: number): string {
  if (rarity <= 1) return 'Common';
  if (rarity === 2) return 'Uncommon';
  if (rarity === 3) return 'Rare';
  if (rarity === 4) return 'Very rare';
  return 'Legendary';
}

export function CardTile({ name, rarity, collected, onPress }: Props) {
  return (
    <Pressable onPress={onPress} accessibilityRole="button" accessibilityLabel={name}>
      <Text>{name}</Text>
      <Text>{rarityLabel(rarity)}</Text>
      {collected ? <Text>Collected</Text> : null}
    </Pressable>
  );
}
