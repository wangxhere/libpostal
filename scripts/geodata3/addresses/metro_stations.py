from geodata3.addresses.config import address_config

import random

from geodata3.addresses.config import address_config
from geodata3.addresses.numbering import NumericPhrase
from geodata3.encoding import safe_decode


class MetroStationPhrase(NumericPhrase):
    key = 'metro_stations.alphanumeric'
    dictionaries = ['qualifiers']


class MetroStation(object):
    @classmethod
    def phrase(cls, station, language, country=None):
        if station is None:
            return None
        phrase_prob = address_config.get_property('metro_stations.alphanumeric_phrase_probability', language, country=country, default=0.0)
        if random.random() < phrase_prob:
            return MetroStationPhrase.phrase(station, language, country=country)

        return None
