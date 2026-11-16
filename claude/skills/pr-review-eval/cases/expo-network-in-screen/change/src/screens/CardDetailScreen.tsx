import { useEffect, useState } from 'react';
import { ScrollView, Text, View } from 'react-native';

import { apiFetch } from '../sync/api';

type Producer = { id: string; name: string; village: string };

export function CardDetailScreen({ cardId }: { cardId: string }) {
  const [producers, setProducers] = useState<Producer[]>([]);

  useEffect(() => {
    apiFetch(`/v1/cards/${cardId}/producers`).then((res) => setProducers(res.producers));
  }, [cardId]);

  return (
    <ScrollView>
      {producers.map((producer, index) => (
        <View key={index}>
          <Text>{producer.name}</Text>
          <Text>{producer.village}</Text>
        </View>
      ))}
    </ScrollView>
  );
}
