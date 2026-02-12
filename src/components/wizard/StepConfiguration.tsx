'use client';

import { useFormContext } from 'react-hook-form';
import type { WizardFormValues, DataValidationResult } from '@/schemas/wizardSchema';
import {
  FormField,
  FormItem,
  FormLabel,
  FormControl,
  FormDescription,
  FormMessage,
} from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { Switch } from '@/components/ui/switch';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from '@/components/ui/collapsible';
import { Card, CardContent } from '@/components/ui/card';
import { ThemePicker } from './ThemePicker';
import { ChevronDown } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useState } from 'react';

interface StepConfigurationProps {
  validationResult: DataValidationResult;
}

export function StepConfiguration({ validationResult }: StepConfigurationProps) {
  const form = useFormContext<WizardFormValues>();
  const displayMode = form.watch('displayMode');
  const [advancedOpen, setAdvancedOpen] = useState(false);

  return (
    <div className="space-y-8 max-w-2xl mx-auto">
      {/* Display mode */}
      <FormField
        control={form.control}
        name="displayMode"
        render={({ field }) => (
          <FormItem>
            <FormLabel>Display Mode</FormLabel>
            <FormControl>
              <RadioGroup
                value={field.value}
                onValueChange={field.onChange}
                className="grid grid-cols-3 gap-3"
              >
                {[
                  { value: 'frequency', label: 'Percentages', desc: 'Column percentages' },
                  { value: 'counts', label: 'Counts', desc: 'Raw frequency counts' },
                  { value: 'both', label: 'Both', desc: 'Separate sheets / workbooks' },
                ].map((option) => (
                  <label key={option.value} className="cursor-pointer">
                    <RadioGroupItem value={option.value} className="sr-only" />
                    <Card
                      className={cn(
                        'transition-all hover:border-foreground/20',
                        field.value === option.value && 'ring-2 ring-ct-blue border-ct-blue'
                      )}
                    >
                      <CardContent className="p-3 text-center">
                        <span className="text-sm font-medium">{option.label}</span>
                        <p className="text-xs text-muted-foreground mt-0.5">{option.desc}</p>
                      </CardContent>
                    </Card>
                  </label>
                ))}
              </RadioGroup>
            </FormControl>
          </FormItem>
        )}
      />

      {/* Separate workbooks (only when displayMode === 'both') */}
      {displayMode === 'both' && (
        <FormField
          control={form.control}
          name="separateWorkbooks"
          render={({ field }) => (
            <FormItem className="flex items-center gap-3 rounded-lg border p-4">
              <FormControl>
                <Switch checked={field.value} onCheckedChange={field.onChange} />
              </FormControl>
              <div className="space-y-0.5">
                <FormLabel className="text-sm">Separate workbooks</FormLabel>
                <FormDescription>
                  Generate two .xlsx files instead of two sheets in one workbook.
                </FormDescription>
              </div>
            </FormItem>
          )}
        />
      )}

      {/* Color theme */}
      <FormField
        control={form.control}
        name="theme"
        render={({ field }) => (
          <FormItem>
            <FormLabel>Color Theme</FormLabel>
            <FormControl>
              <ThemePicker value={field.value} onChange={field.onChange} />
            </FormControl>
          </FormItem>
        )}
      />

      {/* Stat testing threshold */}
      <FormField
        control={form.control}
        name="statTestingThreshold"
        render={({ field }) => (
          <FormItem>
            <FormLabel>Significance Threshold</FormLabel>
            <div className="flex items-center gap-2">
              <FormControl>
                <Input
                  type="number"
                  min={50}
                  max={99}
                  className="w-24 font-mono"
                  value={field.value}
                  onChange={(e) => field.onChange(Number(e.target.value))}
                />
              </FormControl>
              <span className="text-sm text-muted-foreground">%</span>
            </div>
            <FormDescription>
              Confidence level for column-proportion tests. 90% is standard for market research.
            </FormDescription>
            <FormMessage />
          </FormItem>
        )}
      />

      {/* Min base size */}
      <FormField
        control={form.control}
        name="minBaseSize"
        render={({ field }) => (
          <FormItem>
            <FormLabel>Minimum Base Size</FormLabel>
            <div className="flex items-center gap-2">
              <FormControl>
                <Input
                  type="number"
                  min={0}
                  className="w-24 font-mono"
                  value={field.value}
                  onChange={(e) => field.onChange(Number(e.target.value))}
                />
              </FormControl>
              <span className="text-sm text-muted-foreground">respondents</span>
            </div>
            <FormDescription>
              Suppress stat testing for columns below this base. 0 = no minimum.
            </FormDescription>
            <FormMessage />
          </FormItem>
        )}
      />

      {/* Weight variable */}
      <FormField
        control={form.control}
        name="weightVariable"
        render={({ field }) => (
          <FormItem>
            <FormLabel>Weight Variable</FormLabel>
            <Select
              value={field.value || '__none__'}
              onValueChange={(val) => field.onChange(val === '__none__' ? undefined : val)}
            >
              <FormControl>
                <SelectTrigger className="w-full">
                  <SelectValue placeholder="None (unweighted)" />
                </SelectTrigger>
              </FormControl>
              <SelectContent>
                <SelectItem value="__none__">None (unweighted)</SelectItem>
                {validationResult.weightCandidates.map((c) => (
                  <SelectItem key={c.column} value={c.column}>
                    <span className="font-mono">{c.column}</span>
                    {c.label && (
                      <span className="text-muted-foreground ml-2">— {c.label}</span>
                    )}
                    <span className="text-muted-foreground ml-2">(mean: {c.mean.toFixed(3)})</span>
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            <FormDescription>
              {validationResult.weightCandidates.length > 0
                ? 'Detected from your data. Select to apply weighted analysis.'
                : 'No weight variables detected in your data.'}
            </FormDescription>
          </FormItem>
        )}
      />

      {/* Advanced (collapsible) */}
      <Collapsible open={advancedOpen} onOpenChange={setAdvancedOpen}>
        <CollapsibleTrigger className="flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground transition-colors">
          <ChevronDown
            className={cn('h-4 w-4 transition-transform', advancedOpen && 'rotate-180')}
          />
          Advanced options
        </CollapsibleTrigger>
        <CollapsibleContent className="mt-4 space-y-4">
          <FormField
            control={form.control}
            name="stopAfterVerification"
            render={({ field }) => (
              <FormItem className="flex items-center gap-3 rounded-lg border p-4">
                <FormControl>
                  <Switch checked={field.value} onCheckedChange={field.onChange} />
                </FormControl>
                <div className="space-y-0.5">
                  <FormLabel className="text-sm">Stop after verification</FormLabel>
                  <FormDescription>
                    Skip R execution and Excel generation. Useful for reviewing table definitions before running.
                  </FormDescription>
                </div>
              </FormItem>
            )}
          />
        </CollapsibleContent>
      </Collapsible>
    </div>
  );
}
