declare module "ngeohash" {
  /**
   * Encode a latitude/longitude pair into a GeoHash string.
   * @param latitude  in degrees
   * @param longitude in degrees
   * @param precision optional length (chars) of resulting hash
   */
  export function encode(
    latitude: number,
    longitude: number,
    precision?: number
  ): string;

  /**
   * Decode a GeoHash string into [latitude, longitude].
   */
  export function decode(hash: string): [number, number];

  /**
   * Return the 8 adjacent GeoHashes at the same precision.
   */
  export function neighbors(hash: string): string[];
}
