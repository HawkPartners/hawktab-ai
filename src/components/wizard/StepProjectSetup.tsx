'use client';

import { useFormContext } from 'react-hook-form';
import type { WizardFormValues } from '@/schemas/wizardSchema';
import {
  FormField,
  FormItem,
  FormLabel,
  FormControl,
  FormDescription,
  FormMessage,
} from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Switch } from '@/components/ui/switch';
import { Card, CardContent } from '@/components/ui/card';
import { cn } from '@/lib/utils';
import { BarChart3, Info, Layers, Shuffle, XCircle } from 'lucide-react';

const PROJECT_TYPES = [
  {
    value: 'standard' as const,
    label: 'Standard',
    description: 'Standard crosstab with banner cuts',
    icon: BarChart3,
  },
  {
    value: 'segmentation' as const,
    label: 'Segmentation',
    description: 'Segment-based analysis with assignments',
    icon: Layers,
  },
  {
    value: 'maxdiff' as const,
    label: 'MaxDiff',
    description: 'MaxDiff / best-worst scaling analysis',
    icon: Shuffle,
  },
] as const;

export function StepProjectSetup() {
  const form = useFormContext<WizardFormValues>();
  const projectSubType = form.watch('projectSubType');
  const segmentationHasAssignments = form.watch('segmentationHasAssignments');
  const maxdiffHasMessageList = form.watch('maxdiffHasMessageList');
  const maxdiffHasAnchoredScores = form.watch('maxdiffHasAnchoredScores');
  const bannerMode = form.watch('bannerMode');

  return (
    <div className="space-y-8 max-w-2xl mx-auto">
      {/* Project name */}
      <FormField
        control={form.control}
        name="projectName"
        render={({ field }) => (
          <FormItem>
            <FormLabel>Project Name</FormLabel>
            <FormControl>
              <Input placeholder="e.g. Q4 Brand Tracker" {...field} />
            </FormControl>
            <FormMessage />
          </FormItem>
        )}
      />

      {/* Research objectives */}
      <FormField
        control={form.control}
        name="researchObjectives"
        render={({ field }) => (
          <FormItem>
            <FormLabel>Research Objectives</FormLabel>
            <FormControl>
              <Textarea
                placeholder="Brief description of what this study aims to understand (helps AI generate better banner cuts if auto-generating)"
                rows={3}
                {...field}
              />
            </FormControl>
            <FormDescription>Optional. Helps guide auto-generated banner plans.</FormDescription>
          </FormItem>
        )}
      />

      {/* Project type cards */}
      <FormField
        control={form.control}
        name="projectSubType"
        render={({ field }) => (
          <FormItem>
            <FormLabel>Project Type</FormLabel>
            <FormControl>
              <RadioGroup
                value={field.value}
                onValueChange={field.onChange}
                className="grid grid-cols-3 gap-3"
              >
                {PROJECT_TYPES.map((type) => {
                  const Icon = type.icon;
                  const isSelected = field.value === type.value;
                  return (
                    <label key={type.value} className="cursor-pointer">
                      <RadioGroupItem value={type.value} className="sr-only" />
                      <Card
                        className={cn(
                          'transition-all hover:border-foreground/20',
                          isSelected && 'ring-2 ring-ct-blue border-ct-blue'
                        )}
                      >
                        <CardContent className="flex flex-col items-center gap-2 p-4 text-center">
                          <Icon className={cn('h-6 w-6', isSelected ? 'text-ct-blue' : 'text-muted-foreground')} />
                          <span className="text-sm font-medium">{type.label}</span>
                          <span className="text-xs text-muted-foreground">{type.description}</span>
                        </CardContent>
                      </Card>
                    </label>
                  );
                })}
              </RadioGroup>
            </FormControl>
          </FormItem>
        )}
      />

      {/* Conditional: segmentation */}
      {projectSubType === 'segmentation' && (
        <div className="space-y-3">
          <FormField
            control={form.control}
            name="segmentationHasAssignments"
            render={({ field }) => (
              <FormItem className="flex items-center gap-3 rounded-lg border p-4">
                <FormControl>
                  <Switch checked={field.value ?? false} onCheckedChange={field.onChange} />
                </FormControl>
                <div className="space-y-0.5">
                  <FormLabel className="text-sm">My data includes segment assignments</FormLabel>
                  <FormDescription>
                    The .sav file has a column assigning each respondent to a segment.
                  </FormDescription>
                </div>
              </FormItem>
            )}
          />
          {segmentationHasAssignments === false && (
            <div className="flex items-start gap-3 rounded-lg border border-ct-blue/30 bg-ct-blue/5 p-4">
              <Info className="h-4 w-4 text-ct-blue mt-0.5 shrink-0" />
              <p className="text-sm text-muted-foreground">
                Crosstab AI can still generate your tabs, but segments won&apos;t be included as banner cuts.
              </p>
            </div>
          )}
        </div>
      )}

      {/* Conditional: maxdiff */}
      {projectSubType === 'maxdiff' && (
        <div className="space-y-3">
          <FormField
            control={form.control}
            name="maxdiffHasMessageList"
            render={({ field }) => (
              <FormItem className="flex items-center gap-3 rounded-lg border p-4">
                <FormControl>
                  <Switch checked={field.value ?? false} onCheckedChange={field.onChange} />
                </FormControl>
                <div className="space-y-0.5">
                  <FormLabel className="text-sm">I have a message/item list to upload</FormLabel>
                  <FormDescription>
                    An Excel file mapping item codes to descriptions.
                  </FormDescription>
                </div>
              </FormItem>
            )}
          />
          {maxdiffHasMessageList === false && (
            <div className="flex items-start gap-3 rounded-lg border border-ct-blue/30 bg-ct-blue/5 p-4">
              <Info className="h-4 w-4 text-ct-blue mt-0.5 shrink-0" />
              <p className="text-sm text-muted-foreground">
                Crosstab AI can still generate your crosstabs, but message labels may be truncated or use item codes instead of full text.
              </p>
            </div>
          )}

          <FormField
            control={form.control}
            name="maxdiffHasAnchoredScores"
            render={({ field }) => (
              <FormItem className="flex items-center gap-3 rounded-lg border p-4">
                <FormControl>
                  <Switch checked={field.value ?? false} onCheckedChange={field.onChange} />
                </FormControl>
                <div className="space-y-0.5">
                  <FormLabel className="text-sm">Anchored probability scores appended</FormLabel>
                  <FormDescription>
                    Data includes anchored MaxDiff scores (not just raw choices).
                  </FormDescription>
                </div>
              </FormItem>
            )}
          />
          {maxdiffHasAnchoredScores === false && (
            <div className="flex items-start gap-3 rounded-lg border border-ct-red/40 bg-ct-red/5 p-4">
              <XCircle className="h-4 w-4 text-ct-red mt-0.5 shrink-0" />
              <p className="text-sm text-ct-red">
                Anchored probability scores must be appended to the .sav file before running MaxDiff crosstabs. Have your simulator analyst append these scores and re-upload.
              </p>
            </div>
          )}
        </div>
      )}

      {/* Banner plan mode */}
      <FormField
        control={form.control}
        name="bannerMode"
        render={({ field }) => (
          <FormItem>
            <FormLabel>Banner Plan</FormLabel>
            <FormControl>
              <RadioGroup
                value={field.value}
                onValueChange={field.onChange}
                className="grid grid-cols-2 gap-3"
              >
                <label className="cursor-pointer">
                  <RadioGroupItem value="upload" className="sr-only" />
                  <Card
                    className={cn(
                      'transition-all hover:border-foreground/20',
                      field.value === 'upload' && 'ring-2 ring-ct-blue border-ct-blue'
                    )}
                  >
                    <CardContent className="p-4 text-center">
                      <span className="text-sm font-medium">I have a banner plan</span>
                      <p className="text-xs text-muted-foreground mt-1">Upload a PDF or DOCX</p>
                    </CardContent>
                  </Card>
                </label>
                <label className="cursor-pointer">
                  <RadioGroupItem value="auto_generate" className="sr-only" />
                  <Card
                    className={cn(
                      'transition-all hover:border-foreground/20',
                      field.value === 'auto_generate' && 'ring-2 ring-ct-blue border-ct-blue'
                    )}
                  >
                    <CardContent className="p-4 text-center">
                      <span className="text-sm font-medium">Auto-generate for me</span>
                      <p className="text-xs text-muted-foreground mt-1">AI creates banner cuts from your data</p>
                    </CardContent>
                  </Card>
                </label>
              </RadioGroup>
            </FormControl>
          </FormItem>
        )}
      />

      {/* Banner hints — always shown */}
      <FormField
        control={form.control}
        name="bannerHints"
        render={({ field }) => (
          <FormItem>
            <FormLabel>
              {bannerMode === 'upload' ? 'Banner Notes' : 'Banner Hints'}
            </FormLabel>
            <FormControl>
              <Textarea
                placeholder={
                  bannerMode === 'upload'
                    ? 'Any special instructions about the banner plan (optional)'
                    : 'e.g. "Include Total, Gender, Age groups, Region. Break HCP specialty into cardiologist vs other."'
                }
                rows={3}
                {...field}
              />
            </FormControl>
            <FormDescription>
              {bannerMode === 'upload'
                ? 'Optional notes about your banner plan.'
                : 'Tell the AI what cuts you want. Be as specific or general as you like.'}
            </FormDescription>
          </FormItem>
        )}
      />
    </div>
  );
}
