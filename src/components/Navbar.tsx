// noinspection JSUnusedGlobalSymbols

import React from 'react';
import {View, Text, TouchableOpacity, StyleSheet} from 'react-native';
import {useNavigation, useRoute} from '@react-navigation/native';

const navItems = [
  {label: 'Home', route: 'Home'},
  {label: 'Dashboard', route: 'Dashboard'},
  {label: 'Task Input', route: 'TaskInput'},
  {label: 'Task Review', route: 'TaskReview'},
  {label: 'Streak Tracker', route: 'Streak'},
  {label: 'Subscription', route: 'Subscribe'},
  {label: 'Stats', route: 'Stats'},
];

export default function Navbar() {
  const navigation = useNavigation();
  const route = useRoute();

  return (
    <View style={styles.nav}>
      {navItems.map(item => (
        <TouchableOpacity
          key={item.route}
          onPress={() => navigation.navigate(item.route as never)}>
          <Text
            style={[
              styles.link,
              route.name === item.route ? styles.active : undefined,
            ]}>
            {item.label}
          </Text>
        </TouchableOpacity>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  nav: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    padding: 16,
    backgroundColor: '#0f172a',
    justifyContent: 'space-around',
  },
  link: {
    color: 'white',
    fontWeight: '500',
    marginVertical: 4,
  },
  active: {
    color: '#38bdf8',
    textDecorationLine: 'underline',
  },
});
