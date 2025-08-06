import { z } from 'zod';

// Simplified data map schema for agent processing
// Only includes essential fields needed for variable validation
export const DataMapSchema = z.array(z.object({
  Column: z.string(),        // Variable name: "S2", "S2a", "A3r1"
  Description: z.string(),   // Question text
  Answer_Options: z.string() // "1=Cardiologist,2=Internal Medicine"
}));

export type DataMapType = z.infer<typeof DataMapSchema>;

// Individual data map item type for easier handling
export const DataMapItemSchema = z.object({
  Column: z.string(),
  Description: z.string(),
  Answer_Options: z.string()
});

export type DataMapItemType = z.infer<typeof DataMapItemSchema>;

// Schema validation utilities
export const validateDataMap = (data: unknown): DataMapType => {
  return DataMapSchema.parse(data);
};

export const isValidDataMap = (data: unknown): data is DataMapType => {
  return DataMapSchema.safeParse(data).success;
};

// Helper functions for data map processing
export const findVariable = (dataMap: DataMapType, columnName: string): DataMapItemType | undefined => {
  return dataMap.find(item => item.Column.toLowerCase() === columnName.toLowerCase());
};

export const getVariableNames = (dataMap: DataMapType): string[] => {
  return dataMap.map(item => item.Column);
};

export const searchByDescription = (dataMap: DataMapType, searchTerm: string): DataMapItemType[] => {
  const term = searchTerm.toLowerCase();
  return dataMap.filter(item => 
    item.Description.toLowerCase().includes(term) ||
    item.Answer_Options.toLowerCase().includes(term)
  );
};