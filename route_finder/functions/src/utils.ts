export function isValidLocation(location: any): boolean {
  return (
    location &&
    typeof location === "object" &&
    typeof location.address === "string" && location.address.trim() !== "" &&
    typeof location.coordinates === "object" && location.coordinates !== null &&
    typeof location.coordinates.latitude === "number" &&
    typeof location.coordinates.longitude === "number"
  );
}