import { FlatList, Text, View } from 'react-native';

import { formatRarity } from '../features/collection/formatRarity';
import { useCollection } from '../features/collection/useCollection';

export function CollectionScreen() {
  const cards = useCollection();

  return (
    <FlatList
      data={cards}
      keyExtractor={(card) => card.id}
      renderItem={({ item }) => (
        <View>
          <Text>{item.name}</Text>
          <Text>{formatRarity(item.rarity)}</Text>
        </View>
      )}
    />
  );
}
